import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/routes/routes_manager.dart';
import '../widgets/custom_points_badge.dart';
import '../../data/home_repository.dart';
import '../../data/models/station_model.dart';
import '../../data/models/route_model.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onScanRequested;
  const HomeScreen({super.key, this.onScanRequested});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final HomeRepository _repository = HomeRepository();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng? _userLocation;
  List<StationModel> _allStations = [];
  List<LatLng> _polylinePoints = [];
  bool _isLoading = false; 
  bool _isSearching = false;
  StreamSubscription<Position>? _positionStream;

  StationModel? _selectedFromStation;
  StationModel? _selectedToStation;

  List<Marker> _cachedMarkers = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _fromController.dispose();
    _toController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    _loadInitialLocation();
    _loadStations();
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, distanceFilter: 20),
    ).listen((Position pos) {
      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _updateMarkers();
        });
      }
    });
  }

  Future<void> _loadInitialLocation() async {
    try {
      Position position = await _getGeoLocation();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _updateMarkers();
        });
        _mapController.move(_userLocation!, 14.5);
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<void> _loadStations() async {
    try {
      final stations = await _repository.getStations();
      if (mounted) {
        setState(() {
          _allStations = stations;
          _updateMarkers();
        });
      }
    } catch (e) {
      debugPrint("Stations error: $e");
    }
  }

  void _updateMarkers() {
    _cachedMarkers = [
      if (_userLocation != null) _buildUserLocationMarker(),
      ..._allStations.map((s) => _buildStationMarker(s)),
    ];
  }

  Future<Position> _getGeoLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    return await Geolocator.getCurrentPosition();
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

  List<StationModel> _getOrderedTripSegment() {
    if (_selectedFromStation == null || _selectedToStation == null) return [];
    List<StationModel> zoneStations = _allStations.where((s) => s.zone == _selectedFromStation!.zone).toList();
    int startIndex = zoneStations.indexWhere((s) => s.id == _selectedFromStation!.id);
    int endIndex = zoneStations.indexWhere((s) => s.id == _selectedToStation!.id);
    if (startIndex == -1 || endIndex == -1) return [];
    int actualStart = startIndex < endIndex ? startIndex : endIndex;
    int actualEnd = startIndex < endIndex ? endIndex : startIndex;
    List<StationModel> segment = zoneStations.sublist(actualStart, actualEnd + 1);
    return startIndex > endIndex ? segment.reversed.toList() : segment;
  }

  void _triggerRouteDrawing() async {
    List<StationModel> segment = _getOrderedTripSegment();
    if (segment.isEmpty) return;
    
    List<LatLng> routeWaypoints = segment.map((s) => s.position).toList();
    
    if (routeWaypoints.length >= 2) {
      final bounds = LatLngBounds.fromPoints(routeWaypoints);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(70.w)));
    }

    try {
      final routeData = await _repository.getRouteBetweenStations(routeWaypoints);
      if (mounted) {
        setState(() {
          _polylinePoints = routeData.points;
        });
        if (_polylinePoints.isNotEmpty) {
           final bounds = LatLngBounds.fromPoints(_polylinePoints);
           _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(70.w)));
        }
      }
    } catch (e) {
      debugPrint("Routing Error: $e");
    }
  }

  Future<void> _handleFindTrip() async {
    if (_selectedFromStation == null || _selectedToStation == null) return;
    setState(() => _isSearching = true);
    
    try {
      final data = await _repository.searchTrip(_selectedFromStation!.id, _selectedToStation!.id);
      
      List<StationModel> zoneStations = _allStations.where((s) => s.zone == _selectedFromStation!.zone).toList();
      int startIndex = zoneStations.indexWhere((s) => s.id == _selectedFromStation!.id);
      int endIndex = zoneStations.indexWhere((s) => s.id == _selectedToStation!.id);
      
      List<StationModel> allRouteStations = zoneStations;
      if (startIndex > endIndex) {
        allRouteStations = zoneStations.reversed.toList();
      }

      if (mounted) {
        final result = await Navigator.pushNamed(context, RoutesManager.busTracking, arguments: {
          'busId': data['id'],
          'startStationId': _selectedFromStation!.id,
          'endStationId': _selectedToStation!.id,
          'from': _selectedFromStation!.name,
          'to': _selectedToStation!.name,
          'zone': _selectedFromStation!.zone,
          'busNumber': data['busNumber'],
          'arrivalTime': data['estimatedArrivalTime'],
          'distance': data['distanceToStationKm'],
          'stations': allRouteStations.map((s) => {'name': s.name, 'latLong': s.latLong, 'zone': s.zone}).toList(),
          'polylinePoints': _polylinePoints,
        });
        if (result == "OPEN_QR" && widget.onScanRequested != null) widget.onScanRequested!();
      }
    } catch (e) {
      if (mounted) _showErrorDialog("Bus Not Found", "No available buses on this route currently.");
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)), content: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bus_alert, color: const Color(0xFFB71C1C), size: 50.sp), SizedBox(height: 15.h), Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)), SizedBox(height: 8.h), Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: Colors.grey)), SizedBox(height: 20.h), ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0XFF054F3A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))), child: const Text("OK", style: TextStyle(color: Colors.white)))])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const _StaticHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B6A4C)))
                : Stack(
                    children: [
                      _buildMap(),
                      Positioned(bottom: 0, left: 0, right: 0, child: _buildSearchCard()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return RepaintBoundary(
      child: SizedBox(
        height: 0.6.sh, 
        width: double.infinity,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userLocation ?? const LatLng(30.1451, 31.6310), 
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
            if (_polylinePoints.isNotEmpty) 
              PolylineLayer(polylines: [
                Polyline(points: _polylinePoints, color: RouteModel.getColorFromName(_selectedFromStation?.zone ?? ""), strokeWidth: 4.0)
              ]),
            MarkerLayer(markers: _cachedMarkers),
          ],
        ),
      ),
    );
  }

  Marker _buildUserLocationMarker() => Marker(point: _userLocation!, width: 40, height: 40, child: Stack(alignment: Alignment.center, children: [Container(width: 30, height: 30, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withAlpha(51))), Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue, border: Border.all(color: Colors.white, width: 2)))]));

  Marker _buildStationMarker(StationModel station) => Marker(point: station.position, width: 35, height: 35, child: GestureDetector(onTap: () {
    _animatedMapMove(station.position, 16.0);
    _showStationDetails(station);
  }, child: Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Padding(padding: const EdgeInsets.all(2.0), child: Container(decoration: BoxDecoration(color: RouteModel.getColorFromName(station.zone), shape: BoxShape.circle), child: const Icon(Icons.departure_board, color: Colors.white, size: 14))))));

  void _showStationDetails(StationModel station) {
    final color = RouteModel.getColorFromName(station.zone);
    showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)), content: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.location_on, color: color, size: 45.sp), SizedBox(height: 15.h), Text(station.name, textAlign: TextAlign.center, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)), Text(station.zone, style: TextStyle(color: color, fontSize: 13.sp, fontWeight: FontWeight.w500)), SizedBox(height: 20.h), ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0XFF054F3A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))), child: const Text("Done", style: TextStyle(color: Colors.white)))])));
  }

  Widget _buildSearchCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 15, offset: const Offset(0, -5))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("From:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          _buildSearchField("Starting Station", _fromController, true),
          SizedBox(height: 12.h),
          const Text("To:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          _buildSearchField("Destination Station", _toController, false),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: _isSearching ? null : _handleFindTrip,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0XFF054F3A), minimumSize: Size(double.infinity, 55.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r))),
            child: _isSearching ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Trip & Bus", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(String hint, TextEditingController controller, bool isFrom) => TextField(controller: controller, readOnly: true, onTap: () => _showStationPicker(controller, isFrom), decoration: InputDecoration(hintText: hint, prefixIcon: Icon(Icons.search, color: Colors.grey[400]), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade300)), contentPadding: EdgeInsets.symmetric(vertical: 10.h)));

  void _showStationPicker(TextEditingController controller, bool isFrom) {
    final searchController = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) {
      return StatefulBuilder(builder: (context, setModalState) {
        List<StationModel> stationsToDisplay = _allStations;
        if (!isFrom && _selectedFromStation != null) {
          stationsToDisplay = _allStations.where((s) => s.zone == _selectedFromStation!.zone && s.id != _selectedFromStation!.id).toList();
        }
        List<StationModel> filtered = stationsToDisplay.where((s) => s.name.toLowerCase().contains(searchController.text.toLowerCase())).toList();
        return Container(height: 0.8.sh, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25.r))), padding: EdgeInsets.all(20.w), child: Column(children: [Container(width: 40.w, height: 4.h, color: Colors.grey[300]), SizedBox(height: 20.h), const Text("Select Station", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), if (!isFrom && _selectedFromStation != null) Text("Route: ${_selectedFromStation!.zone}", style: TextStyle(color: RouteModel.getColorFromName(_selectedFromStation!.zone), fontSize: 13)), SizedBox(height: 15.h), TextField(controller: searchController, decoration: InputDecoration(hintText: "Search stations...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r))), onChanged: (value) => setModalState(() {})), Expanded(child: filtered.isEmpty ? const Center(child: Text("No stations found")) : ListView.builder(itemCount: filtered.length, itemBuilder: (context, index) { 
          final station = filtered[index]; 
          final rColor = RouteModel.getColorFromName(station.zone);
          return ListTile(
            leading: Icon(Icons.location_on, color: rColor),
            title: Text(station.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(station.zone, style: TextStyle(color: rColor, fontSize: 12)),
            onTap: () {
              setState(() {
                controller.text = station.name;
                if (isFrom) {
                  _selectedFromStation = station;
                  _selectedToStation = null;
                  _toController.clear();
                  _polylinePoints = [];
                  _animatedMapMove(station.position, 16.0);
                } else {
                  _selectedToStation = station;
                  _triggerRouteDrawing();
                }
              });
              Navigator.pop(context);
            },
          );
        }))]));
      });
    });
  }
}

class _StaticHeader extends StatelessWidget {
  const _StaticHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text("Transit", style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
              Text("Way", style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1B6A4C))),
              SizedBox(width: 4.w),
              Icon(Icons.location_on, color: const Color(0xFF1B6A4C), size: 24.sp)
            ]),
            const CustomPointsBadge()
          ],
        ),
      ),
    );
  }
}
