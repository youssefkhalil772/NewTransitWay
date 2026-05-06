part of 'routes_screen.dart';

// ignore_for_file: use_build_context_synchronously

class _RoutesScreenState extends State<RoutesScreen>
    with TickerProviderStateMixin {
  // ─── Controllers ──────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  final TrackingService _trackingService = TrackingService();
  final HomeRepository _repository = HomeRepository();

  // ─── Location & movement ──────────────────────────────────────────────────
  LatLng? _currentLocation;
  double _currentSpeed = 0.0;
  double _smoothedHeading = 0.0;
  double _currentHeading = 0.0;
  bool _followBus = true; // auto-follow — toggled off when user pans map
  
  List<StationModel> _localStations = [];
  List<StationModel> get activeStations => _localStations.isNotEmpty ? _localStations : widget.stations;

  // ─── Trip state ───────────────────────────────────────────────────────────
  bool _isTripActive = false;
  bool _isMapReady = false;
  bool _isProcessingArrival = false;
  bool _isFetchingRoute = false;
  bool _isEndingTrip = false;
  bool _isInitialized = false;

  // ─── Route & stations ─────────────────────────────────────────────────────
  List<LatLng> _polylinePoints = [];
  int _nextStationIndex = 0;
  String _currentNextStationName = "Searching...";
  String _etaToNextStation = "...";

  // ─── Subscriptions & timers ───────────────────────────────────────────────
  StreamSubscription? _locationSubscription;
  Timer? _rerouteDebounce;

  // ─── SOS / Crash Detection ────────────────────────────────────────────────
  late final CrashDetector _crashDetector;
  bool _showSosCountdown = false;
  bool _showSosConfirmation = false;
  int _sosCountdownSeconds = 15;
  bool _isSendingSos = false;
  Timer? _sosTimer;
  String? _currentAlertId;

  // ─── Lifecycle ────────────────────────────────────────────────────────────
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
    // لو الـ refreshTrigger اتغير أو حتى لو بنرجع للـ tab والرحلة مش شغالة
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

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_isTripActive) return buildNoTripView();
    // Always show the map — never block. Fallback center is used if GPS not ready yet.
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
                  : const SizedBox.shrink(key: ValueKey('none')),
        ),
      ],
    );
  }

  // ─── State helpers ────────────────────────────────────────────────────────
  
  /// Load position instantly: try last known, then actively request current
  Future<void> _loadLastKnownPosition() async {
    try {
      // 1. Try cached (instant)
      final cached = await Geolocator.getLastKnownPosition();
      if (cached != null && mounted) {
        setState(() => _currentLocation = LatLng(cached.latitude, cached.longitude));
        return;
      }
      // 2. Actively request with short timeout
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
      // 3. Absolute fallback: Cairo center — map always shows
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
        _smoothedHeading = 0.0;
        _currentHeading = 0.0;
        _showSosCountdown = false;
        _showSosConfirmation = false;
        _sosTimer?.cancel();
        _currentAlertId = null;
      });
    }
    if (_isMapReady) _mapController.rotate(0);
  }

  Future<void> _checkTripStatus() async {
    // Primary: if stations were passed in, the trip IS active — no async needed
    if (activeStations.isNotEmpty) {
      if (mounted) {
        setState(() => _isTripActive = true);
        _crashDetector.start();
      }
      return;
    }

    // Fallback: check SharedPreferences (for when screen rebuilds from tab switch)
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
      
      final matchedRoute = allRoutes.firstWhere((r) => r.id == routeId, orElse: () => allRoutes.first);
      
      final stations = allStations.where((s) => s.zone.toLowerCase().trim() == matchedRoute.zone.toLowerCase().trim()).toList();
      
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

  // ─── Station logic ────────────────────────────────────────────────────────
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

  // ─── Map movement ────────────────────────────────────────────────────────
  void _moveMapToLocation(LatLng location) {
    if (!_isMapReady || !_followBus) return;
    // Direct move — no animation delay for real-time feel
    _mapController.move(location, _mapController.camera.zoom);
  }

  // ─── Location stream ──────────────────────────────────────────────────────
  void _listenToLiveUpdates() {
    _locationSubscription =
        _trackingService.locationStream.listen((position) {
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

      // 60fps Smooth Interpolation (Gliding)
      final startLoc = _currentLocation ?? newLoc;
      final startHeading = _currentHeading;
      final headingDiff = (position.heading - startHeading + 540) % 360 - 180;
      final endHeading = startHeading + headingDiff;

      _movementController?.dispose();
      _movementController = AnimationController(
        vsync: this, 
        duration: const Duration(milliseconds: 900) // Slightly less than 1s to finish before next tick
      );

      final latTween = Tween<double>(begin: startLoc.latitude, end: newLoc.latitude);
      final lngTween = Tween<double>(begin: startLoc.longitude, end: newLoc.longitude);
      final headingTween = Tween<double>(begin: startHeading, end: endHeading);

      _movementController!.addListener(() {
        if (!mounted) return;
        final val = _movementController!.value;
        final animLoc = LatLng(latTween.transform(val), lngTween.transform(val));
        
        setState(() {
          _currentLocation = animLoc;
          _currentHeading = headingTween.transform(val);
          _currentSpeed = position.speed * 3.6; // Speed updates instantly
        });
        
        _moveMapToLocation(animLoc);
      });
      
      _movementController!.forward();

      // Logic calculations still use the actual new GPS target, not the animated frame
      if (_polylinePoints.isNotEmpty) {
        final bool onPath = _prunePathBehindBus(newLoc);
        if (!onPath && !_isFetchingRoute) {
          debugPrint("🚨 Off track detected (> 10m). Rerouting...");
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

  // ─── Rerouting ────────────────────────────────────────────────────────────
  void _scheduleReroute() {
    _rerouteDebounce?.cancel();
    _rerouteDebounce = Timer(const Duration(seconds: 2), () {
      if (mounted && !_isFetchingRoute) {
        debugPrint("🔄 Rerouting after leaving path...");
        setState(() => _polylinePoints = []);
        _updateSmartRoute();
      }
    });
  }

  // ─── ETA ──────────────────────────────────────────────────────────────────
  void _calculateETA(LatLng busPos) {
    if (activeStations.isEmpty ||
        _nextStationIndex >= activeStations.length) {
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

  // ─── Path pruning ─────────────────────────────────────────────────────────
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

  // ─── Route fetching ───────────────────────────────────────────────────────
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
        final routeData =
            await _repository.getRouteBetweenStations(waypoints);
        if (mounted) {
          setState(() {
            _polylinePoints = routeData.points;
            _currentNextStationName =
                _nextStationIndex < activeStations.length
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

  // ─── SOS / Crash Detection ────────────────────────────────────────────────

  /// Initialises CrashDetector with callbacks that update the UI via setState.
  void _initCrashDetector() {
    _crashDetector = CrashDetector(
      onCrashDetected: () async {
        debugPrint("💥 CrashDetector Callback Triggered!");
        if (!mounted || _showSosCountdown) return;

        // 1. Show the UI IMMEDIATELY (Critical Path)
        setState(() {
          _showSosCountdown = true;
          _sosCountdownSeconds = 15;
          _showSosConfirmation = false;
        });

        // 2. Start the countdown timer immediately
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

        // 3. Create the database record in the background (Non-blocking)
        if (!_isSendingSos) {
          _isSendingSos = true;
          try {
            final ids = await SosService.loadIds();
            debugPrint("📡 Creating background alert record for IDs: $ids");
            final alertId = await SosService.triggerSos(
              driverId: ids.driverId,
              busId: ids.busId,
            );

            if (alertId != null && mounted) {
              _currentAlertId = alertId;
            }
          } catch (e) {
            debugPrint("🛑 Background SOS trigger failed: $e");
          } finally {
            _isSendingSos = false;
          }
        }
      },
    );
  }

  /// Cancel an in-progress countdown — driver indicated they are fine.
  void _cancelSos() async {
    _sosTimer?.cancel();
    final alertId = _currentAlertId;
    
    if (mounted) {
      setState(() {
        _showSosCountdown = false;
        _sosCountdownSeconds = 15;
        _currentAlertId = null;
      });
    }

    if (alertId != null) {
      await SosService.sendSafe(alertId);
    }
  }

  /// Driver manually pressed the red SOS button (not from crash detection).
  void _sendSosManually() {
    _sosTimer?.cancel();

    // If there's already an active alert (from crash detection), just escalate
    if (_currentAlertId != null) {
      _executeEmergency();
      return;
    }

    // No active alert — this is a fully manual SOS trigger
    // Show UI immediately first
    if (mounted) {
      setState(() {
        _showSosCountdown = false;
        _showSosConfirmation = false;
      });
    }

    // Trigger + immediately escalate to emergency (no countdown for manual press)
    _triggerAndSendEmergency();
  }

  /// Trigger a brand-new SOS alert and immediately escalate to emergency.
  /// Used when the driver presses the manual SOS button without a crash event.
  Future<void> _triggerAndSendEmergency() async {
    if (_isSendingSos) return;
    _isSendingSos = true;

    try {
      final ids = await SosService.loadIds();
      debugPrint('🆘 Manual SOS: triggering with ids=$ids');

      final alertId = await SosService.triggerSos(
        driverId: ids.driverId,
        busId: ids.busId,
      );

      if (alertId != null) {
        await SosService.sendEmergency(alertId);
        debugPrint('🚨 Manual SOS: emergency sent for alertId=$alertId');
      }

      if (mounted) {
        setState(() {
          _showSosConfirmation = true;
          _currentAlertId = null;
        });
      }
    } catch (e) {
      debugPrint('🛑 Manual SOS failed: $e');
    } finally {
      _isSendingSos = false;
    }
  }

  /// Shared logic that actually fires the SOS call and shows the confirmation.
  Future<void> _executeEmergency() async {
    if (_isSendingSos) return;
    if (mounted) setState(() => _isSendingSos = true);

    try {
      var alertId = _currentAlertId;

      // If no alertId yet (background trigger still running), wait a bit
      if (alertId == null) {
        debugPrint('⏳ _executeEmergency: waiting for alertId...');
        await Future.delayed(const Duration(seconds: 2));
        alertId = _currentAlertId;
      }

      if (alertId != null) {
        await SosService.sendEmergency(alertId);
        debugPrint('🚨 Emergency sent for alertId=$alertId');
      } else {
        // Last resort: trigger a new one and send emergency
        debugPrint('⚠️ No alertId — triggering new SOS for emergency');
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
      debugPrint('🛑 SOS execution failed: $e');
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

