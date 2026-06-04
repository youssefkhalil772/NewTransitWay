part of 'routes_screen.dart';

class _RoutesScreenState extends State<RoutesScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TrackingService _trackingService = TrackingService();
  final HomeRepository _repository = HomeRepository();

  LatLng? _currentLocation;
  double _currentSpeed = 0.0;
  double _currentHeading = 0.0;
  final bool _followBus =
      true; // auto-follow â€” toggled off when user pans map

  List<StationModel> _localStations = [];
  List<StationModel> get activeStations =>
      _localStations.isNotEmpty ? _localStations : widget.stations;

  bool _isTripActive = false;
  bool _isMapReady = false;
  bool _isProcessingArrival = false;
  bool _isFetchingRoute = false;
  bool _isEndingTrip = false;
  bool _isInitialized = false;

  List<LatLng> _polylinePoints = [];
  int _nextStationIndex = 0;
  String _currentNextStationName = "Searching...";
  String _etaToNextStation = "...";

  StreamSubscription? _locationSubscription;
  Timer? _rerouteDebounce;

  late final CrashDetector _crashDetector;
  bool _showSosCountdown = false;
  bool _showSosConfirmation = false;
  bool _showSafeConfirmation = false;
  int _sosCountdownSeconds = 15;
  bool _isSendingSos = false;
  Timer? _sosTimer;
  String? _currentAlertId;

  @override
  void initState() {
    super.initState();
    _initCrashDetector();
    _loadLastKnownPosition(); // Show map immediately
    _checkTripStatus();
    _listenToLiveUpdates();
  }

  @override
  void didUpdateWidget(covariant RoutesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _checkTripStatus();
    }
  }

  AnimationController? _movementController;

  @override
  void dispose() {
    _movementController?.dispose();
    _crashDetector.stop();
    _rerouteDebounce?.cancel();
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTripActive) return buildNoTripView();
    return Stack(
      children: [
        buildMainScreen(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showSosCountdown
              ? SosCountdownOverlay(
                  key: const ValueKey('countdown'),
                  secondsLeft: _sosCountdownSeconds,
                  onCancel: _cancelSos,
                  onSendNow: _sendSosManually,
                )
              : _showSosConfirmation
              ? SosSentConfirmation(
                  key: const ValueKey('confirmation'),
                  onDismiss: () => setState(() => _showSosConfirmation = false),
                )
              : _showSafeConfirmation
              ? SosSentConfirmation(
                  key: const ValueKey('safe_confirmation'),
                  isSafeMode: true,
                  onDismiss: () =>
                      setState(() => _showSafeConfirmation = false),
                )
              : const SizedBox.shrink(key: ValueKey('none')),
        ),
      ],
    );
  }

  Future<void> _loadLastKnownPosition() async {
    try {
      final cached = await Geolocator.getLastKnownPosition();
      if (cached != null && mounted) {
        setState(
          () => _currentLocation = LatLng(cached.latitude, cached.longitude),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 3),
        ),
      );
      if (mounted) {
        setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {
      if (mounted && _currentLocation == null) {
        setState(() => _currentLocation = const LatLng(30.0444, 31.2357));
      }
    }
  }

  void _resetTripState() {
    _crashDetector.stop();
    _rerouteDebounce?.cancel();
    if (mounted) {
      setState(() {
        _isTripActive = false;
        _nextStationIndex = 0;
        _polylinePoints = [];
        _currentNextStationName = "...";
        _etaToNextStation = "...";
        _currentLocation = null;
        _isProcessingArrival = false;
        _isFetchingRoute = false;
        _isEndingTrip = false;
        _isInitialized = false;
        _currentHeading = 0.0;
        _showSosCountdown = false;
        _showSosConfirmation = false;
        _showSafeConfirmation = false;
        _sosTimer?.cancel();
        _currentAlertId = null;
      });
    }
    if (_isMapReady) _mapController.rotate(0);
  }

  Future<void> _checkTripStatus() async {
    if (activeStations.isNotEmpty) {
      if (mounted) {
        setState(() => _isTripActive = true);
        _crashDetector.start();
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool active = prefs.getBool('isTripActive') ?? false;
    if (mounted) {
      setState(() {
        _isTripActive = active;
        if (!active) {
          _currentLocation = null;
          _isInitialized = false;
        }
      });
      if (active) {
        await _fetchStationsForActiveTrip();
        _crashDetector.start();
        if (_currentLocation != null) _findNearestStationIndex();
      }
    }
  }

  Future<void> _fetchStationsForActiveTrip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routeId = prefs.getInt('routeId');
      if (routeId == null) return;

      final allRoutes = await DriverDataManager().getRoutes();
      final allStations = await DriverDataManager().getStations();

      final matchedRoute = allRoutes.firstWhere(
        (r) => r.id == routeId,
        orElse: () => allRoutes.first,
      );

      final rZone = matchedRoute.zone.toLowerCase().replaceAll(' ', '');
      final stations =
          allStations
              .where((s) => s.zone.toLowerCase().replaceAll(' ', '') == rZone)
              .toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      if (mounted) {
        setState(() {
          _localStations = stations;
        });
        if (_currentLocation != null) {
          _findNearestStationIndex();
          _updateSmartRoute();
        }
      }
    } catch (_) {}
  }

  void _findNearestStationIndex() {
    if (activeStations.isEmpty || _currentLocation == null) return;

    int nearestIndex = 0;
    double minDist = double.maxFinite;

    for (int i = 0; i < activeStations.length; i++) {
      final double d = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        activeStations[i].position.latitude,
        activeStations[i].position.longitude,
      );
      if (d < minDist) {
        minDist = d;
        nearestIndex = i;
      }
    }

    setState(() {
      _nextStationIndex = nearestIndex;
      _currentNextStationName = activeStations[nearestIndex].name;
    });
  }

  void _checkArrivalLogic(LatLng busPos) {
    if (_isProcessingArrival ||
        activeStations.isEmpty ||
        _nextStationIndex >= activeStations.length) {
      return;
    }

    final target = activeStations[_nextStationIndex];
    final double dist = Geolocator.distanceBetween(
      busPos.latitude,
      busPos.longitude,
      target.position.latitude,
      target.position.longitude,
    );

    if (dist < 50) {
      _isProcessingArrival = true;
      setState(() => _nextStationIndex++);
      _updateSmartRoute().then((_) => _isProcessingArrival = false);
    }
  }

  void _moveMapToLocation(LatLng location, double heading) {
    if (!_isMapReady || !_followBus) return;
    _mapController.move(location, _mapController.camera.zoom);
    _mapController.rotate(heading);
  }

  void _listenToLiveUpdates() {
    _locationSubscription = _trackingService.locationStream.listen((position) {
      if (!mounted || !_isTripActive) return;

      final LatLng newLoc = LatLng(position.latitude, position.longitude);

      if (!_isInitialized && _isTripActive) {
        _isInitialized = true;
        setState(() {
          _currentLocation = newLoc;
          _currentSpeed = position.speed * 3.6;
        });
        _findNearestStationIndex();
        _updateSmartRoute();
        return;
      }

      final startLoc = _currentLocation ?? newLoc;
      final startHeading = _currentHeading;
      final headingDiff = (position.heading - startHeading + 540) % 360 - 180;
      final endHeading = startHeading + headingDiff;

      _movementController?.dispose();
      _movementController = AnimationController(
        vsync: this,
        duration: const Duration(
          milliseconds: 900,
        ), // Slightly less than 1s to finish before next tick
      );

      final latTween = Tween<double>(
        begin: startLoc.latitude,
        end: newLoc.latitude,
      );
      final lngTween = Tween<double>(
        begin: startLoc.longitude,
        end: newLoc.longitude,
      );
      final headingTween = Tween<double>(begin: startHeading, end: endHeading);

      _movementController!.addListener(() {
        if (!mounted) return;
        final val = _movementController!.value;
        final animLoc = LatLng(
          latTween.transform(val),
          lngTween.transform(val),
        );

        final animHeading = headingTween.transform(val);

        setState(() {
          _currentLocation = animLoc;
          _currentHeading = animHeading;
          _currentSpeed = position.speed * 3.6; // Speed updates instantly
        });

        _moveMapToLocation(animLoc, animHeading);
      });

      _movementController!.forward();

      if (_polylinePoints.isNotEmpty) {
        final bool onPath = _prunePathBehindBus(newLoc);
        if (!onPath && !_isFetchingRoute) {
          debugPrint("ðŸš¨ Off track detected (> 10m). Rerouting...");
          _scheduleReroute();
        }
      }

      _calculateETA(newLoc);

      _checkArrivalLogic(newLoc);

      if (_polylinePoints.isEmpty &&
          activeStations.isNotEmpty &&
          !_isFetchingRoute) {
        _updateSmartRoute();
      }
    });
  }

  void _scheduleReroute() {
    _rerouteDebounce?.cancel();
    _rerouteDebounce = Timer(const Duration(seconds: 2), () {
      if (mounted && !_isFetchingRoute) {
        debugPrint("ðŸ”„ Rerouting after leaving path...");
        setState(() => _polylinePoints = []);
        _updateSmartRoute();
      }
    });
  }

  void _calculateETA(LatLng busPos) {
    if (activeStations.isEmpty || _nextStationIndex >= activeStations.length) {
      _etaToNextStation = "0 min";
      return;
    }

    final target = activeStations[_nextStationIndex];
    final double distMeters = Geolocator.distanceBetween(
      busPos.latitude,
      busPos.longitude,
      target.position.latitude,
      target.position.longitude,
    );

    final double speedKmh = _currentSpeed > 5 ? _currentSpeed : 20.0;
    final double speedMps = speedKmh / 3.6;
    final int minutes = (distMeters / speedMps / 60).round();

    _etaToNextStation = minutes < 1 ? "< 1 min" : "~$minutes min";
  }

  bool _prunePathBehindBus(LatLng busPos) {
    if (_polylinePoints.length < 2) return true;

    int closestIndex = -1;
    double minDist = double.maxFinite;

    for (int i = 0; i < _polylinePoints.length; i++) {
      final double d = Geolocator.distanceBetween(
        busPos.latitude,
        busPos.longitude,
        _polylinePoints[i].latitude,
        _polylinePoints[i].longitude,
      );
      if (d < minDist) {
        minDist = d;
        closestIndex = i;
      }
    }

    if (minDist > 10) return false;

    if (closestIndex > 0) {
      _polylinePoints.removeRange(0, closestIndex);
    }

    if (_polylinePoints.isNotEmpty) {
      _polylinePoints[0] = busPos;
    }

    return true;
  }

  Future<void> _updateSmartRoute() async {
    if (_isFetchingRoute ||
        activeStations.isEmpty ||
        !_isTripActive ||
        _currentLocation == null ||
        !mounted) {
      return;
    }

    setState(() => _isFetchingRoute = true);

    try {
      final List<LatLng> waypoints = [_currentLocation!];
      for (int i = _nextStationIndex; i < activeStations.length; i++) {
        waypoints.add(activeStations[i].position);
      }

      if (waypoints.length >= 2) {
        final routeData = await _repository.getRouteBetweenStations(waypoints);
        if (mounted) {
          setState(() {
            _polylinePoints = routeData.points;
            _currentNextStationName = _nextStationIndex < activeStations.length
                ? activeStations[_nextStationIndex].name
                : "Trip Completed";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
    } finally {
      if (mounted) setState(() => _isFetchingRoute = false);
    }
  }

  void _initCrashDetector() {
    _crashDetector = CrashDetector(
      onCrashDetected: () async {
        debugPrint("ðŸ’¥ CrashDetector Callback Triggered!");
        if (!mounted || _showSosCountdown) return;

        setState(() {
          _showSosCountdown = true;
          _sosCountdownSeconds = 15;
          _showSosConfirmation = false;
          _showSafeConfirmation = false;
        });

        _sosTimer?.cancel();
        _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            _sosCountdownSeconds--;
          });
          if (_sosCountdownSeconds <= 0) {
            timer.cancel();
            _executeEmergency();
          }
        });
      },
    );
  }

  void _cancelSos() async {
    _sosTimer?.cancel();
    final alertId = _currentAlertId;

    if (mounted) {
      setState(() {
        _showSosCountdown = false;
        _sosCountdownSeconds = 15;
        _currentAlertId = null;
        _showSafeConfirmation = true;
      });
    }

    if (alertId != null) {
      await SosService.sendSafe(alertId);
    }
  }

  void _sendSosManually() {
    _sosTimer?.cancel();
    if (mounted) {
      setState(() {
        _showSosCountdown = false;
        _sosCountdownSeconds = 15;
      });
    }
    _showSosBottomSheet(context);
  }

  void _showSosBottomSheet(BuildContext context) {
    final messageController = TextEditingController();
    bool isSendingBreakdown = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            margin: EdgeInsets.only(top: 60.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 30.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 50.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 28.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency & Reports',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Report an issue or call for immediate help',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30.h),

                    Text(
                      'What happened?',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText:
                            'Describe the issue (e.g., engine stopped, flat tire...)',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: const BorderSide(
                            color: Color(0xFF1B4D3E),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: EdgeInsets.all(16.w),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      onPressed: () {
                        final msg = messageController.text.trim();
                        Navigator.pop(ctx);
                        _triggerAndSendEmergency(msg.isNotEmpty ? msg : null);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emergency,
                            size: 22.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'SOS Emergency',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      onPressed: isSendingBreakdown
                          ? null
                          : () async {
                              final msg = messageController.text.trim();
                              if (msg.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please describe the issue first.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              setSheetState(() => isSendingBreakdown = true);
                              Navigator.pop(ctx);
                              await _sendBreakdownReport(msg);
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          isSendingBreakdown
                              ? SizedBox(
                                  width: 22.sp,
                                  height: 22.sp,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.build,
                                  size: 22.sp,
                                  color: Colors.white,
                                ),
                          SizedBox(width: 12.w),
                          Text(
                            isSendingBreakdown
                                ? 'Sending...'
                                : 'Report Breakdown',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendBreakdownReport(String message) async {
    try {
      final ids = await SosService.loadIds();
      await SosService.sendBreakdown(
        driverId: ids.driverId,
        busId: ids.busId,
        message: message,
      );
      if (mounted) {
        setState(() => _showSosConfirmation = true);
      }
    } catch (e) {
      debugPrint('ðŸ›‘ Breakdown report failed: $e');
    }
  }

  Future<void> _triggerAndSendEmergency([String? message]) async {
    if (_isSendingSos) return;
    _isSendingSos = true;

    try {
      final ids = await SosService.loadIds();
      debugPrint('ðŸ†˜ Manual SOS: triggering with ids=$ids');

      final alertId = await SosService.triggerSos(
        driverId: ids.driverId,
        busId: ids.busId,
        message: message,
      );

      if (alertId != null) {
        await SosService.sendEmergency(alertId);
        debugPrint('ðŸš¨ Manual SOS: emergency sent for alertId=$alertId');
      }

      if (mounted) {
        setState(() {
          _showSosConfirmation = true;
          _currentAlertId = null;
        });
      }
    } catch (e) {
      debugPrint('ðŸ›‘ Manual SOS failed: $e');
    } finally {
      _isSendingSos = false;
    }
  }

  Future<void> _executeEmergency() async {
    if (_isSendingSos) return;
    if (mounted) setState(() => _isSendingSos = true);

    try {
      var alertId = _currentAlertId;

      if (alertId == null) {
        debugPrint('â³ _executeEmergency: waiting for alertId...');
        await Future.delayed(const Duration(seconds: 2));
        alertId = _currentAlertId;
      }

      if (alertId != null) {
        await SosService.sendEmergency(alertId);
        debugPrint('ðŸš¨ Emergency sent for alertId=$alertId');
      } else {
        debugPrint('âš ï¸ No alertId â€” triggering new SOS for emergency');
        final ids = await SosService.loadIds();
        final newId = await SosService.triggerSos(
          driverId: ids.driverId,
          busId: ids.busId,
        );
        if (newId != null) {
          await SosService.sendEmergency(newId);
        }
      }

      if (mounted) {
        setState(() {
          _showSosCountdown = false;
          _showSosConfirmation = true;
          _currentAlertId = null;
        });
      }
    } catch (e) {
      debugPrint('ðŸ›‘ SOS execution failed: $e');
      if (mounted) {
        setState(() {
          _showSosCountdown = false;
          _currentAlertId = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isSendingSos = false);
    }
  }
}
