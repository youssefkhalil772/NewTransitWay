import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/home_repository.dart';
import '../widgets/custom_points_badge.dart';
import 'tracking_view.dart';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> with TickerProviderStateMixin {
  final HomeRepository _repository = HomeRepository();
  final MapController _mapController = MapController();
  LatLng? _busLocation; 
  bool _isTracking = true;

  final Color appGreen = const Color(0xFF1B4D3E);
  List<Marker> _cachedMarkers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final int busId = args['busId'] ?? 0;
        if (busId != 0) _startLiveTracking(busId);
      }
    });
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

  void _animatedMove(LatLng destLocation) {
    if (_busLocation == null) return;
    final latTween = Tween<double>(begin: _busLocation!.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _busLocation!.longitude, end: destLocation.longitude);
    final controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      if (mounted) {
        setState(() => _busLocation = LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)));
      }
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) controller.dispose();
    });
    controller.forward();
  }

  Future<void> _startLiveTracking(int busId) async {
    bool isFirstLocation = true;
    while (_isTracking && mounted) {
      try {
        final data = await _repository.getBuses();
        final bus = data.firstWhere((item) => item['latestLocation'] != null && item['latestLocation']['busId'] == busId, orElse: () => null);
        if (bus != null && mounted) {
          final latest = bus['latestLocation'];
          LatLng newLoc = LatLng((latest['latitude'] as num).toDouble(), (latest['longitude'] as num).toDouble());
          
          if (isFirstLocation) {
            setState(() {
              _busLocation = newLoc;
              isFirstLocation = false;
            });
            _mapController.move(_busLocation!, 14.5);
          } else if (newLoc != _busLocation) {
            _animatedMove(newLoc);
          }
        }
      } catch (e) {
        debugPrint("Tracking Error: $e");
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  void _updateMarkers(String busNum, Color routeColor, List<dynamic> stations) {
    _cachedMarkers = [
      if (_busLocation != null) Marker(
        point: _busLocation!, width: 100.w, height: 85.h,
        child: _BusMarkerWidget(busNum: busNum, routeColor: routeColor),
      ),
      ...stations.map((s) {
        var p = s['latLong'].toString().split('&');
        LatLng pos = LatLng(double.parse(p[0].trim()), double.parse(p[1].trim()));
        return Marker(
          point: pos, width: 30, height: 30,
          child: GestureDetector(
            onTap: () => _animatedMapMove(pos, 16.0),
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
              child: Padding(padding: const EdgeInsets.all(2.0), child: Container(decoration: BoxDecoration(color: routeColor, shape: BoxShape.circle), child: const Icon(Icons.departure_board, color: Colors.white, size: 12))),
            ),
          ),
        );
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return const Scaffold(body: Center(child: Text("No Data Available")));

    final routeColor = _getRouteColor(args['zone']);
    final List<dynamic> stations = args['stations'] ?? [];
    _updateMarkers(args['busNumber']?.toString() ?? "---", routeColor, stations);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const _StaticTrackingHeader(),
          Expanded(
            child: Stack(
              children: [
                _buildMapSection(routeColor),
                _buildDetailsBottomSheet(args, routeColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(Color routeColor) {
    return RepaintBoundary(
      child: SizedBox(
        height: 0.35.sh,
        width: double.infinity,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _busLocation ?? const LatLng(30.0444, 31.2357), 
            initialZoom: 14.5,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              keepBuffer: 5, 
              tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 200)),
            ),
            MarkerLayer(markers: _cachedMarkers),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsBottomSheet(Map<String, dynamic> args, Color routeColor) {
    final List<dynamic> stations = args['stations'] ?? [];
    return Positioned(
      top: 0.32.sh, left: 0, right: 0, bottom: 0,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)), 
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bus Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 15.h),
            _buildBusInfoRow(args['busNumber']?.toString() ?? "---", appGreen),
            SizedBox(height: 15.h),
            Text("Arrives In ${args['arrivalTime']}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appGreen)),
            if (args['distance'] != null) Text("Distance: ${args['distance']} KM", style: TextStyle(fontSize: 13, color: Colors.grey)),
            SizedBox(height: 25.h),
            _buildRouteFlow(args['from'] ?? "", args['to'] ?? "", appGreen),
            SizedBox(height: 20.h),
            const Text("Route", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(child: ListView.builder(padding: EdgeInsets.only(top: 10.h), itemCount: stations.length, itemBuilder: (context, index) {
              final station = stations[index];
              var p = station['latLong'].toString().split('&');
              LatLng pos = LatLng(double.parse(p[0].trim()), double.parse(p[1].trim()));
              return InkWell(
                onTap: () => _animatedMapMove(pos, 16.0),
                child: _buildRouteStep(station['name'] ?? "Station", appGreen, isLast: index == stations.length - 1),
              );
            })),
            _buildTrackButton(args, appGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStep(String title, Color color, {bool isLast = false}) => IntrinsicHeight(child: Row(children: [Column(children: [Container(width: 6.w, height: 6.w, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), if (!isLast) Expanded(child: Container(width: 1.w, color: color.withAlpha(76)))]), SizedBox(width: 15.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.black54)), SizedBox(height: isLast ? 10.h : 15.h)]))]));
  Widget _buildBusInfoRow(String busNum, Color color) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Bus Number", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Container(padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15.r)), child: Text(busNum, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)))]);
  Widget _buildRouteFlow(String from, String to, Color color) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: _stationLabel("From", from, CrossAxisAlignment.start)), Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.trending_flat, color: color)), Expanded(child: _stationLabel("To", to, CrossAxisAlignment.end))]);
  Widget _stationLabel(String label, String name, CrossAxisAlignment align) => Column(crossAxisAlignment: align, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)), Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54), overflow: TextOverflow.ellipsis)]);
  
  Widget _buildTrackButton(Map<String, dynamic> args, Color color) {
    return ElevatedButton(
      onPressed: () async {
        final result = await Navigator.push(
          context, 
          CupertinoPageRoute(
            builder: (context) => const TrackingView(), 
            settings: RouteSettings(arguments: args)
          )
        );
        if (result == "OPEN_QR" && mounted) {
          Navigator.pop(context, "OPEN_QR");
        }
      }, 
      style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: Size(double.infinity, 50.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))), 
      child: const Text("Track Bus", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
    );
  }
}

class _BusMarkerWidget extends StatelessWidget {
  final String busNum;
  final Color routeColor;
  const _BusMarkerWidget({required this.busNum, required this.routeColor});

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Positioned(top: 0, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h), decoration: BoxDecoration(color: routeColor, borderRadius: BorderRadius.circular(8.r), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]), child: Text("Bus $busNum", style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold))),
        Transform.translate(offset: Offset(0, -3.h), child: Icon(Icons.arrow_drop_down, color: routeColor, size: 20.sp)),
      ])),
      Positioned(bottom: 10.h, child: Container(padding: EdgeInsets.all(5.w), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.directions_bus, color: routeColor, size: 26.sp))),
    ]);
  }
}

class _StaticTrackingHeader extends StatelessWidget {
  const _StaticTrackingHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        child: Row(
          children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
            Text("TransitWay", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
            const Spacer(),
            const CustomPointsBadge(),
          ],
        ),
      ),
    );
  }
}
