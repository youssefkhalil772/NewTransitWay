part of 'routes_screen.dart';

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

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _rerouteDebounce?.cancel();
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_isTripActive) return buildNoTripView();
    if (_currentLocation == null) return buildLoadingView();
    return buildMainScreen();
  }

  // ─── State helpers ────────────────────────────────────────────────────────
  void _resetTripState() {
    _rerouteDebounce?.cancel();
    if (mounted) {
      setState(() {
        _isTripActive = false; // مهم جداً عشان يظهر الـ No Trip View
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
      });
    }
    if (_isMapReady) _mapController.rotate(0);
  }

  Future<void> _checkTripStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool active = prefs.getBool('isTripActive') ?? false;
    if (mounted) {
      setState(() {
        _isTripActive = active;
        // لو مفيش رحلة، نأكد إن الحالة متصفرة
        if (!active) {
          _currentLocation = null;
          _isInitialized = false;
        }
      });
      if (active && _currentLocation != null) _findNearestStationIndex();
    }
  }

  // ─── Station logic ────────────────────────────────────────────────────────
  void _findNearestStationIndex() {
    if (widget.stations.isEmpty || _currentLocation == null) return;

    int nearestIndex = 0;
    double minDist = double.maxFinite;

    for (int i = 0; i < widget.stations.length; i++) {
      final double d = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        widget.stations[i].position.latitude,
        widget.stations[i].position.longitude,
      );
      if (d < minDist) {
        minDist = d;
        nearestIndex = i;
      }
    }

    setState(() {
      _nextStationIndex = nearestIndex;
      _currentNextStationName = widget.stations[nearestIndex].name;
    });
  }

  void _checkArrivalLogic(LatLng busPos) {
    if (_isProcessingArrival ||
        widget.stations.isEmpty ||
        _nextStationIndex >= widget.stations.length) return;

    final target = widget.stations[_nextStationIndex];
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

  // ─── Map animation ────────────────────────────────────────────────────────
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!_isMapReady) return;
    
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    final animation =
        CurvedAnimation(parent: controller, curve: Curves.easeOut);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        destZoom,
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
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

      setState(() {
        _currentLocation = newLoc;
        _currentSpeed = position.speed * 3.6;

        final double diff =
            (position.heading - _smoothedHeading + 540) % 360 - 180;
        _smoothedHeading += diff * 0.3;
        _currentHeading = _smoothedHeading;

        if (_polylinePoints.isNotEmpty) {
          final bool onPath = _prunePathBehindBus(newLoc);
          if (!onPath && !_isFetchingRoute) {
            debugPrint("🚨 Off track detected (> 10m). Rerouting...");
            _scheduleReroute();
          }
        }

        _calculateETA(newLoc);
      });

      if (_isMapReady) {
        _animatedMapMove(newLoc, _mapController.camera.zoom);
      }

      _checkArrivalLogic(newLoc);

      if (_polylinePoints.isEmpty &&
          widget.stations.isNotEmpty &&
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
    if (widget.stations.isEmpty ||
        _nextStationIndex >= widget.stations.length) {
      _etaToNextStation = "0 min";
      return;
    }

    final target = widget.stations[_nextStationIndex];
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
        widget.stations.isEmpty ||
        !_isTripActive ||
        _currentLocation == null ||
        !mounted) return;

    setState(() => _isFetchingRoute = true);

    try {
      final List<LatLng> waypoints = [_currentLocation!];
      for (int i = _nextStationIndex; i < widget.stations.length; i++) {
        waypoints.add(widget.stations[i].position);
      }

      if (waypoints.length >= 2) {
        final routeData =
            await _repository.getRouteBetweenStations(waypoints);
        if (mounted) {
          setState(() {
            _polylinePoints = routeData.points;
            _currentNextStationName =
                _nextStationIndex < widget.stations.length
                    ? widget.stations[_nextStationIndex].name
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
}
