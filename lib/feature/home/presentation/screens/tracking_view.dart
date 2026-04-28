import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/custom_points_badge.dart';
import '../../data/home_repository.dart';

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
  
  int _nextStationIndex = 0;
  bool _isFirstUpdate = true;
  double? _busHeading; // لحفظ اتجاه الباص

  final Color appGreen = const Color(0xFF1B4D3E);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataInitialized) {
      args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _isDataInitialized = true;
        _loadStationMarkers();
        _startLiveTracking(args!['busId'] ?? 0);
      }
    }
  }

  @override
  void dispose() {
    _isTracking = false;
    _mapController.dispose();
    super.dispose();
  }

  Color _getRouteColor(String? zone) {
    if (zone == null) return const Color(0xFF1B6A4C);
    if (zone.toLowerCase().contains("cairo")) return const Color(0xFF1B6A4C);
    if (zone.toLowerCase().contains("shrouk")) return const Color(0xFF0D47A1);
    if (zone.toLowerCase().contains("route2")) return const Color(0xFFB71C1C);
    return const Color(0xFF1B6A4C);
  }

  void _loadStationMarkers() {
    final List<dynamic> stations = args!['stations'] ?? [];
    final routeColor = _getRouteColor(args?['zone']);
    setState(() {
      _stationMarkers = stations.map((s) {
        var p = s['latLong'].toString().split('&');
        LatLng pos = LatLng(double.parse(p[0].trim()), double.parse(p[1].trim()));
        return _buildStationMarker(pos, routeColor);
      }).toList();
    });
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.move(LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)), zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) controller.dispose();
    });

    controller.forward();
  }

  // دالة لمسح النقاط التي تجاوزها الباص من المسار
  void _prunePathBehindBus(LatLng busPos) {
    if (_polylinePoints.length < 2) return;
    while (_polylinePoints.length > 1) {
      double distToFirst = Geolocator.distanceBetween(busPos.latitude, busPos.longitude, _polylinePoints[0].latitude, _polylinePoints[0].longitude);
      double distToSecond = Geolocator.distanceBetween(busPos.latitude, busPos.longitude, _polylinePoints[1].latitude, _polylinePoints[1].longitude);
      if (distToSecond < distToFirst || distToFirst < 5) {
        _polylinePoints.removeAt(0);
      } else {
        break;
      }
    }
    _polylinePoints[0] = busPos;
  }

  Future<void> _updateBusAndRoute() async {
    if (_busLocation == null) return;
    try {
      final List<dynamic> stations = args!['stations'] ?? [];
      int userStartStationIndex = stations.indexWhere((s) => s['name'] == args!['from']);
      if (userStartStationIndex == -1) return;

      int closestStationIndex = -1;
      double minDistance = double.maxFinite;

      for (int i = 0; i < stations.length; i++) {
        var p = stations[i]['latLong'].toString().split('&');
        LatLng pos = LatLng(double.parse(p[0].trim()), double.parse(p[1].trim()));
        double distance = Geolocator.distanceBetween(_busLocation!.latitude, _busLocation!.longitude, pos.latitude, pos.longitude);
        if (distance < minDistance) {
          minDistance = distance;
          closestStationIndex = i;
        }
      }

      if (_isFirstUpdate) {
        _nextStationIndex = closestStationIndex;
        _isFirstUpdate = false;
      }

      if (minDistance < 65) { 
        String stationName = stations[closestStationIndex]['name'] ?? "Station";
        if (_lastReachedStation != stationName) {
          _lastReachedStation = stationName;
          _showArrivalPopup = true;
          _isUserStation = (stationName == args!['from']);
          
          if (_nextStationIndex <= closestStationIndex) {
            _nextStationIndex = closestStationIndex + 1;
          }
          if (mounted) setState(() {});
        }
      }

      List<LatLng> routeWaypoints = [_busLocation!];
      if (_nextStationIndex <= userStartStationIndex) {
        for (int i = _nextStationIndex; i <= userStartStationIndex; i++) {
          var p = stations[i]['latLong'].toString().split('&');
          routeWaypoints.add(LatLng(double.parse(p[0].trim()), double.parse(p[1].trim())));
        }
      }

      if (routeWaypoints.length >= 2) {
        // تم تصحيح الخطأ هنا: إزالة isLiveTracking وإضافة heading
        final routeData = await _repository.getRouteBetweenStations(routeWaypoints, heading: _busHeading);
        if (mounted) {
          setState(() {
            _polylinePoints = routeData.points;
            _distance = (routeData.distanceInMeters / 1000).toStringAsFixed(1);
            int mins = (routeData.durationInSeconds / 60).ceil();
            _arrivalTime = mins > 0 ? "$mins min" : "Arrived";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _polylinePoints = [];
            _distance = "0";
            _arrivalTime = "Arrived";
          });
        }
      }
    } catch (e) {
      debugPrint("Smart Route Error: $e");
    }
  }

  void _animatedMove(LatLng destLocation) {
    if (_busLocation == null) return;
    final startLat = _busLocation!.latitude;
    final startLng = _busLocation!.longitude;
    final latTween = Tween<double>(begin: startLat, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: startLng, end: destLocation.longitude);
    
    final controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      if (mounted) {
        LatLng animatedPos = LatLng(latTween.evaluate(animation), lngTween.evaluate(animation));
        setState(() {
          _busLocation = animatedPos;
          // مسح المسار من خلف الباص في الوقت الفعلي أثناء الأنيميشن
          _prunePathBehindBus(animatedPos);
        });
        _mapController.move(_busLocation!, _mapController.camera.zoom);
      }
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
        _updateBusAndRoute();
      }
    });
    controller.forward();
  }

  Future<void> _startLiveTracking(int busId) async {
    bool isFirstLocation = true;
    while (_isTracking && mounted) {
      try {
        final busesData = await _repository.getBuses();
        final bus = busesData.firstWhere((item) => item['latestLocation'] != null && item['latestLocation']['busId'] == busId, orElse: () => null);
        
        if (bus != null && mounted) {
          final latest = bus['latestLocation'];
          LatLng newLoc = LatLng((latest['latitude'] as num).toDouble(), (latest['longitude'] as num).toDouble());
          
          // تحديث الـ heading لو متاح من السيرفر لضمان سلاسة الخط
          _busHeading = latest['heading']?.toDouble();

          if (isFirstLocation) {
            setState(() { _busLocation = newLoc; isFirstLocation = false; });
            _mapController.move(_busLocation!, 15);
            _updateBusAndRoute();
          } else if (newLoc.latitude != _busLocation!.latitude || newLoc.longitude != _busLocation!.longitude) {
            _animatedMove(newLoc);
          } else {
            _updateBusAndRoute();
          }
        }
      } catch (e) {
        debugPrint("Update Error: $e");
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busLocation == null) return Scaffold(body: Center(child: CircularProgressIndicator(color: appGreen)));
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
                    initialCenter: _busLocation!, 
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      keepBuffer: 5,
                      tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 200)),
                      retinaMode: RetinaMode.isHighDensity(context),
                    ),
                    if (_polylinePoints.isNotEmpty) PolylineLayer(polylines: [Polyline(points: _polylinePoints, color: routeColor, strokeWidth: 5)]),
                    MarkerLayer(markers: [
                      ..._stationMarkers,
                      Marker(point: _busLocation!, width: 100.w, height: 85.h, child: _buildBusMarker(args?['busNumber']?.toString() ?? "1", routeColor)),
                    ]),
                  ],
                ),
                _buildTrackingDetailsCard(),
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
      angle: (_busHeading ?? 0) * (3.14159 / 180), // تدوير الباص في تطبيق اليوزر أيضاً
      child: Stack(alignment: Alignment.center, children: [
        Positioned(top: 0, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8.r)), child: Text("Bus $busNum", style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold))),
          Icon(Icons.arrow_drop_down, color: color, size: 20.sp),
        ])),
        Positioned(bottom: 10.h, child: Container(padding: EdgeInsets.all(5.w), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.directions_bus, color: color, size: 26.sp))),
      ]),
    );
  }

  Widget _buildTrackingDetailsCard() {
    return Align(alignment: Alignment.bottomCenter, child: Container(
        margin: EdgeInsets.all(20.w),
        padding: EdgeInsets.all(25.w),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25.r), boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 15)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _dataDetail(_arrivalTime, "Time"),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              _dataDetail("$_distance KM", "Distance"),
            ],
          ),
          const Divider(height: 30),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _infoColumn("From", args?['from'] ?? ""),
            Icon(Icons.trending_flat, color: appGreen),
            _infoColumn("To", args?['to'] ?? ""),
          ]),
        ])
    ));
  }

  Widget _dataDetail(String value, String label) => Column(children: [Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: appGreen)), Text(label, style: TextStyle(color: Colors.grey, fontSize: 12.sp))]);
  Widget _infoColumn(String label, String value) => Column(children: [Text(label, style: TextStyle(color: Colors.grey, fontSize: 12.sp)), SizedBox(width: 80.w, child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))]);

  Widget _buildHeader() {
    return Container(padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 5.h, bottom: 10.h), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 2)]), child: Row(children: [
      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
      Text("TransitWay", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: appGreen)),
      const Spacer(),
      const CustomPointsBadge(),
      SizedBox(width: 15.w),
    ]));
  }

  Widget _buildArrivalNotification() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      top: _showArrivalPopup ? MediaQuery.of(context).padding.top + 10.h : -150.h,
      left: 15.w, right: 15.w,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(color: appGreen, borderRadius: BorderRadius.circular(20.r), boxShadow: [BoxShadow(color: Colors.black.withAlpha(76), blurRadius: 15, offset: const Offset(0, 8))]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(padding: EdgeInsets.all(8.w), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: Icon(Icons.directions_bus, color: Colors.white, size: 22.sp)),
              SizedBox(width: 12.w),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_isUserStation ? "Your Bus is Here!" : "Bus Arrived!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                Text(_isUserStation ? "Get ready to ride at $_lastReachedStation" : "Reached: $_lastReachedStation", style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
              ])),
            ]),
            SizedBox(height: 15.h),
            if (_isUserStation)
              ElevatedButton(
                onPressed: () {
                  setState(() => _showArrivalPopup = false);
                  Navigator.pop(context, "OPEN_QR");
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: appGreen, minimumSize: Size(double.infinity, 45.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                child: const Text("Scan QR to Pay", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            else
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => setState(() => _showArrivalPopup = false), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: appGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))), child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }

  Marker _buildStationMarker(LatLng point, Color color) => Marker(point: point, width: 30, height: 30, child: GestureDetector(onTap: () => _animatedMapMove(point, 16.0), child: Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Padding(padding: const EdgeInsets.all(2.0), child: Container(decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: const Icon(Icons.departure_board, color: Colors.white, size: 12))))));
}
