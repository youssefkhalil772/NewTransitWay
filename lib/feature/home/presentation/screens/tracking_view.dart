import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_points_badge.dart';
import '../../data/home_repository.dart';
import '../../../../core/networking/api_constants.dart';
import '../../../../core/networking/supabase_init.dart';

class TrackingView extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const TrackingView({super.key, this.onNavigateToTab});

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> with TickerProviderStateMixin {
  final HomeRepository _repository = HomeRepository();
  final MapController _mapController = MapController();

  Map<String, dynamic>? args;
  List<LatLng> _polylinePoints = [];
  bool _isDataInitialized = false;
  LatLng? _busLocation;
  bool _isTracking = true;
  List<Marker> _stationMarkers = [];
  bool _showArrivalPopup = false;
  String _lastReachedStation = "";
  bool _isUserStation = false;

  String _arrivalTime = "...";
  String _distance = "...";

  bool _isFirstUpdate = true;
  double? _busHeading;
  int _nextStationIndex = 0;
  Timer? _fallbackTimer;
  RealtimeChannel? _broadcastChannel;
  AnimationController? _movementController;
  final Color appGreen = const Color(0xFF1B4D3E);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataInitialized) {
      final originalArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (originalArgs != null) {
        args = Map<String, dynamic>.from(originalArgs);
        // Ensure stations list is mutable
        if (args!['stations'] != null) {
          args!['stations'] = List<Map<String, dynamic>>.from(
            (args!['stations'] as List).map((s) => Map<String, dynamic>.from(s))
          );
        }
        
        _isDataInitialized = true;
        
        if (args!['lat'] != null && args!['lng'] != null) {
          _busLocation = LatLng(
            (args!['lat'] as num).toDouble(), 
            (args!['lng'] as num).toDouble()
          );
        }

        _loadStationMarkers();
        final dynamic busId = args!['busId'];
        final dynamic busNum = args!['busNumber'];
        _startLiveTracking(busId, busNum);

        if (_busLocation != null) {
          _fetchFullRoute();
        }
      }
    }
  }

  @override
  void dispose() {
    _isTracking = false;
    _busStreamSubscription?.cancel();
    _broadcastChannel?.unsubscribe();
    _fallbackTimer?.cancel();
    _movementController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Color _getRouteColor(String? zone) {
    if (zone == null) return const Color(0xFF1B6A4C);
    if (zone.toLowerCase().contains("cairo")) return const Color(0xFF1B6A4C);
    if (zone.toLowerCase().contains("shrouk")) return const Color(0xFF0D47A1);
    return const Color(0xFF1B6A4C);
  }

  void _loadStationMarkers() {
    final List<dynamic> stations = args!['stations'] ?? [];
    final routeColor = _getRouteColor(args?['zone']);
    final String? fromName = args!['from'];

    setState(() {
      _stationMarkers = stations.map((s) {
        var p = s['latLong'].toString().split('&');
        LatLng pos = LatLng(double.parse(p[0].trim()), double.parse(p[1].trim()));

        // Make all stations look the same (no special green pin)
        return _buildStationMarker(pos, routeColor);
      }).toList();
    });
  }


  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _prunePathBehindBus(LatLng busPos) {
    if (_polylinePoints.length < 2) return;

    int closestIndex = -1;
    double minDistance = double.maxFinite;

    for (int i = 0; i < _polylinePoints.length; i++) {
      double d = Geolocator.distanceBetween(
        busPos.latitude,
        busPos.longitude,
        _polylinePoints[i].latitude,
        _polylinePoints[i].longitude,
      );
      if (d < minDistance) {
        minDistance = d;
        closestIndex = i;
      }
    }

    if (closestIndex > 0) {
      setState(() {
        _polylinePoints.removeRange(0, closestIndex);
        if (_polylinePoints.isNotEmpty) {
          _polylinePoints[0] = busPos;
        }
      });
    } else if (_polylinePoints.isNotEmpty) {
      setState(() => _polylinePoints[0] = busPos);
    }
  }

  double _calculateRemainingDistance() {
    double total = 0;
    for (int i = 0; i < _polylinePoints.length - 1; i++) {
      total += Geolocator.distanceBetween(
        _polylinePoints[i].latitude,
        _polylinePoints[i].longitude,
        _polylinePoints[i + 1].latitude,
        _polylinePoints[i + 1].longitude,
      );
    }
    return total;
  }

  Future<void> _fetchFullRoute() async {
    if (_busLocation == null) return;
    try {
      final List<dynamic> stations = args!['stations'] ?? [];
      final String? startStationName = args!['from'];

      // Find the user's boarding station index
      int boardingIndex = stations.indexWhere((s) => s['name'] == startStationName);
      if (boardingIndex == -1) boardingIndex = stations.length - 1;

      // Start from the closest upcoming station (not from 0) so we don't route backwards
      List<LatLng> routeWaypoints = [_busLocation!];
      
      // If the bus hasn't passed the boarding station yet
      if (_nextStationIndex <= boardingIndex) {
        for (int i = _nextStationIndex; i <= boardingIndex; i++) {
          var p = stations[i]['latLong'].toString().split('&');
          final stPos = LatLng(double.parse(p[0].trim()), double.parse(p[1].trim()));
          
          // Skip station if bus is practically already there
          final d = Geolocator.distanceBetween(
            _busLocation!.latitude, _busLocation!.longitude,
            stPos.latitude, stPos.longitude,
          );
          if (d > 30) routeWaypoints.add(stPos);
        }
      }

      // Must have at least 2 points to draw a route
      if (routeWaypoints.length < 2) {
        // Add boarding station directly if not added yet
        var p = stations[boardingIndex]['latLong'].toString().split('&');
        routeWaypoints.add(LatLng(double.parse(p[0].trim()), double.parse(p[1].trim())));
      }

      debugPrint("Fetching route with ${routeWaypoints.length} waypoints");

      final routeData = await _repository.getRouteBetweenStations(
        routeWaypoints,
        heading: _busHeading,
      );
      if (mounted) {
        setState(() {
          _polylinePoints = routeData.points;
          final distKm = routeData.distanceInMeters / 1000;
          _distance = distKm.toStringAsFixed(1);
          final mins = (routeData.durationInSeconds / 60).ceil();
          _arrivalTime = mins > 0 ? "$mins min" : "Arrived!";
        });
      }
    } catch (e) {
      debugPrint("Route Fetch Error: $e");
    }
  }

  Future<void> _checkArrival(LatLng busPos) async {
    final List<dynamic> stations = args!['stations'] ?? [];
    for (int i = 0; i < stations.length; i++) {
      var p = stations[i]['latLong'].toString().split('&');
      LatLng pos = LatLng(double.parse(p[0].trim()), double.parse(p[1].trim()));
      double distance = Geolocator.distanceBetween(
        busPos.latitude,
        busPos.longitude,
        pos.latitude,
        pos.longitude,
      );

      if (distance < 70) {
        String stationName = stations[i]['name'] ?? "Station";
        if (_lastReachedStation != stationName) {
          _lastReachedStation = stationName;
          _showArrivalPopup = true;
          _isUserStation = (stationName == args!['from']);
          
          // Mark this station and all previous ones as reached
          for (int j = 0; j <= i; j++) {
            stations[j]['reached'] = true;
          }

          _nextStationIndex = i + 1;
          _fetchFullRoute();
          if (mounted) setState(() {});
        }
      }
    }
  }

  void _startGlidingAnimation(LatLng destLocation, double destHeading) {
    if (_busLocation == null) return;
    final startLoc = _busLocation!;
    final startHeading = _busHeading ?? 0.0;

    // Shortest path for heading rotation
    final headingDiff = (destHeading - startHeading + 540) % 360 - 180;
    final endHeading = startHeading + headingDiff;
    
    _movementController?.dispose();
    _movementController = AnimationController(
        vsync: this, 
        duration: const Duration(milliseconds: 900)
    );

    final latTween = Tween<double>(begin: startLoc.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: startLoc.longitude, end: destLocation.longitude);
    final headingTween = Tween<double>(begin: startHeading, end: endHeading);

    _movementController!.addListener(() {
      if (!mounted) return;
      final val = _movementController!.value;
      final animLoc = LatLng(latTween.transform(val), lngTween.transform(val));
      final animHeading = headingTween.transform(val);
      
      setState(() {
        _busLocation = animLoc;
        _busHeading = animHeading;
      });
      _mapController.move(animLoc, _mapController.camera.zoom);
      _mapController.rotate(animHeading);
    });


    _movementController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _prunePathBehindBus(destLocation);
        _checkArrival(destLocation);
        if (_calculateRemainingDistance() < 300) {
          _fetchFullRoute();
        }
      }
    });

    _movementController!.forward();
  }


  StreamSubscription<List<Map<String, dynamic>>>? _busStreamSubscription;

  void _handleTrackingUpdate(Map<String, dynamic> data) {
    debugPrint("TrackingView: Processing data for keys: ${data.keys.toList()}");
    final lat = data['current_lat'] ?? data['lat'] ?? data['latitude'];
    final lng = data['current_lng'] ?? data['lng'] ?? data['longitude'];
    
    if (lat == null || lng == null) {
      debugPrint("TrackingView: Warning - received data with null coordinates");
      return;
    }

    final newLoc = LatLng((lat as num).toDouble(), (lng as num).toDouble());
    final double newHeading = data['heading']?.toDouble() ?? _busHeading ?? 0.0;

    if (_isFirstUpdate || _busLocation == null) {
      debugPrint("TrackingView: First location set to $newLoc");
      final List<dynamic> stations = args!['stations'] ?? [];
      double minD = double.maxFinite;
      int closest = 0;
      for (int i = 0; i < stations.length; i++) {
        var p = stations[i]['latLong'].toString().split('&');
        final pos = LatLng(double.parse(p[0].trim()), double.parse(p[1].trim()));
        final d = Geolocator.distanceBetween(
          newLoc.latitude, newLoc.longitude, pos.latitude, pos.longitude);
        if (d < minD) { minD = d; closest = i; }
      }
      _nextStationIndex = closest;
      setState(() { 
        _busLocation = newLoc; 
        _busHeading = newHeading;
        _isFirstUpdate = false; 
      });
      _mapController.move(newLoc, 15);
      _mapController.rotate(newHeading);
      _fetchFullRoute();
    } else {
      final moved = Geolocator.distanceBetween(
        _busLocation!.latitude, _busLocation!.longitude,
        newLoc.latitude, newLoc.longitude,
      );
      final double headingDiff = (newHeading - (_busHeading ?? 0.0)).abs();

      debugPrint("TrackingView: Bus moved $moved meters, heading change $headingDiff");
      // Threshold lowered to 2 meters or 5 degrees to avoid missing small movements
      if (moved > 2 || headingDiff > 5) {
        _startGlidingAnimation(newLoc, newHeading);
      }
    }


  }


  Future<void> _startLiveTracking(dynamic busId, dynamic busNum) async {
    _busStreamSubscription?.cancel();
    debugPrint("🚀 TrackingView: Starting Realtime Monitor for busId=$busId");

    try {
      // 1. Resolve exact Bus UUID
      var initialData = await SupabaseConfig.client
          .from(ApiConstants.busesTable)
          .select()
          .eq('id', busId.toString())
          .maybeSingle();

      initialData ??= await SupabaseConfig.client
          .from(ApiConstants.busesTable)
          .select()
          .eq('bus_number', busNum.toString())
          .maybeSingle();

      if (initialData != null && mounted) {
        _handleTrackingUpdate(initialData);
        final String resolvedId = initialData['id'].toString();
        debugPrint("✅ TrackingView: Resolved bus UUID = $resolvedId");

        // 2. Start Realtime Stream (DB updates)
        _busStreamSubscription = SupabaseConfig.client
            .from(ApiConstants.busesTable)
            .stream(primaryKey: ['id'])
            .eq('id', resolvedId)
            .listen((List<Map<String, dynamic>> data) {
          if (!_isTracking || !mounted) return;
          
          if (data.isNotEmpty) {
            final update = data.first;
            _handleTrackingUpdate(update);
          }
        }, onError: (error) {
          debugPrint("🛑 TrackingView: Stream Error: $error");
        });

        // 2.5 Start Realtime Broadcast (60fps updates)
        _broadcastChannel?.unsubscribe();
        _broadcastChannel = SupabaseConfig.client.channel('public-tracking');
        _broadcastChannel!.onBroadcast(
          event: 'bus_moved',
          callback: (payload) {
            if (!_isTracking || !mounted || payload == null) return;
            if (payload['bus_id']?.toString() == resolvedId) {
              _handleTrackingUpdate(payload);
            }
          }
        ).subscribe();

        // 3. Fallback: Polling (Every 5 seconds)
        _fallbackTimer?.cancel();
        _fallbackTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
          if (!_isTracking || !mounted) return;
          try {
            final latest = await SupabaseConfig.client
                .from(ApiConstants.busesTable)
                .select()
                .eq('id', resolvedId)
                .maybeSingle();
            
            if (latest != null && mounted) {
              debugPrint("🔄 TrackingView: Fallback Polling update received");
              _handleTrackingUpdate(latest);
            }
          } catch (e) {
            debugPrint("⚠️ TrackingView: Polling Error: $e");
          }
        });
      } else {
        debugPrint("🛑 TrackingView: Could not resolve bus data for tracking!");
      }
    } catch (e) {
      debugPrint("🛑 TrackingView: Setup Error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final routeColor = _getRouteColor(args?['zone']);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _busLocation ?? const LatLng(30.0444, 31.2357),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),

                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      retinaMode: RetinaMode.isHighDensity(context),
                    ),
                    if (_polylinePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: <Polyline<Object>>[
                          Polyline<Object>(
                            points: _polylinePoints,
                            color: routeColor,
                            strokeWidth: 5,
                            borderColor: Colors.white.withOpacity(0.5),
                            borderStrokeWidth: 2.0,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        ..._stationMarkers,
                        if (_busLocation != null)
                          Marker(
                            point: _busLocation!,
                            width: 100.w,
                            height: 85.h,
                            child: _buildBusMarker(
                              args?['busNumber']?.toString() ?? "1",
                              routeColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // Recenter Button — sits just above the bottom sheet
                Positioned(
                  bottom: 0.35.sh + 12.h,
                  right: 16.w,
                  child: FloatingActionButton.small(
                    heroTag: "recenter_tracking",
                    onPressed: () {
                      if (_busLocation != null) {
                        _animatedMapMove(_busLocation!, 15.0);
                        _mapController.rotate(_busHeading ?? 0.0);
                      }
                    },
                    backgroundColor: Colors.white,
                    elevation: 4,
                    child: Icon(Icons.my_location, color: appGreen),
                  ),
                ),

                DraggableScrollableSheet(
                  initialChildSize: 0.35,
                  minChildSize: 0.2,
                  maxChildSize: 0.8,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 15, offset: const Offset(0, -5))
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: _buildTrackingDetailsContent(),
                      ),
                    );
                  },
                ),
                _buildArrivalNotification(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusMarker(String busNum, Color color) {
    return Transform.rotate(
      angle: (_busHeading ?? 0) * (3.14159 / 180),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    "Bus $busNum",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: color, size: 20.sp),
              ],
            ),
          ),
          Positioned(
            bottom: 10.h,
            child: Container(
              padding: EdgeInsets.all(5.w),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.directions_bus, color: color, size: 26.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingDetailsContent() {
    return Padding(
      padding: EdgeInsets.all(25.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 15.h),
          // Header: boarding station label
          Row(
            children: [
              Icon(Icons.location_pin, color: appGreen, size: 18.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  "Bus arriving at: ${args?['from'] ?? '---'}",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: appGreen,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // ETA + Distance row
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: appGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPulseEtaText(
                  _arrivalTime == "..." ? "Calculating..." : _arrivalTime,
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _dataDetail(
                  _distance == "..." ? "---" : "$_distance km",
                  "📍 Distance",
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoColumn("From", args?['from'] ?? ""),
              Icon(Icons.trending_flat, color: appGreen),
              _infoColumn("To", args?['to'] ?? ""),
            ],
          ),
          SizedBox(height: 20.h),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Route progress",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 15.h),
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (args!['stations'] as List).length,
            itemBuilder: (context, index) {
              final station = args!['stations'][index];
              final bool isReached = station['reached'] == true;
              final bool isLast =
                  index == (args!['stations'] as List).length - 1;

              return IntrinsicHeight(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 14.w,
                          height: 14.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isReached
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            color: isReached ? Colors.white : Colors.white,
                          ),
                          child: isReached
                              ? Center(
                                  child: Container(
                                    width: 8.w,
                                    height: 8.w,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.orange,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: Colors.grey.shade200,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station['name'] ?? "Station",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: isReached
                                  ? Colors.black
                                  : Colors.grey.shade400,
                            ),
                          ),
                          if (index == _nextStationIndex - 1 && !isReached)
                            Text(
                              "Next stop",
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey,
                              ),
                            ),
                          SizedBox(height: isLast ? 10.h : 20.h),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _dataDetail(String value, String label) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: appGreen)),
      Text(label, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
    ],
  );

  Widget _buildPulseEtaText(String eta) {
    final bool isClose = eta.contains("1 min") || eta.contains("2 min") || eta.contains("Arrived");
    
    return Column(
      children: [
        if (isClose)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 1.15),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Text(
                  eta,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              );
            },
            onEnd: () {
              if (mounted) setState(() {});
            },
          )
        else
          Text(eta, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: appGreen)),
        Text("⏱  ETA", style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
      ],
    );
  }

  Widget _infoColumn(String label, String value) => Column(
    children: [
      Text(label, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
      SizedBox(
        width: 80.w,
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 5.h, bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
          Text(
            "TransitWay",
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: appGreen),
          ),
          const Spacer(),
          const CustomPointsBadge(),
          SizedBox(width: 15.w),
        ],
      ),
    );
  }

  Widget _buildArrivalNotification() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      top: _showArrivalPopup ? MediaQuery.of(context).padding.top + 10.h : -150.h,
      left: 15.w,
      right: 15.w,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: appGreen,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(76), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: Icon(Icons.directions_bus, color: Colors.white, size: 22.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isUserStation ? "Your Bus is Here!" : "Bus Arrived!",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      Text(
                        _isUserStation
                            ? "Get ready to ride at $_lastReachedStation"
                            : "Reached: $_lastReachedStation",
                        style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),
            if (_isUserStation)
              ElevatedButton(
                onPressed: () {
                  setState(() => _showArrivalPopup = false);
                  Navigator.pop(context, "OPEN_QR");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: appGreen,
                  minimumSize: Size(double.infinity, 45.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text("Scan QR to Pay", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showArrivalPopup = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: appGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Marker _buildStationMarker(LatLng point, Color color) => Marker(
    point: point,
    width: 30,
    height: 30,
    child: GestureDetector(
      onTap: () => _animatedMapMove(point, 16.0),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Container(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const Icon(Icons.departure_board, color: Colors.white, size: 12),
          ),
        ),
      ),
    ),
  );
}