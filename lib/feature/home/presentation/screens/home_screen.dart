import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transite_way/core/networking/supabase_init.dart';
import 'package:transite_way/core/networking/connectivity_service.dart';
import 'package:transite_way/feature/driver/presentation/screens/widgets/skeleton_loader.dart';
import 'package:transite_way/feature/home/data/user_data_manager.dart';
import '../../../../core/routes/routes_manager.dart';
import '../../../notifications/data/notification_service.dart';
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
  bool _isLoading = true;
  bool _isSearching = false;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription? _busesSubscription;

  StationModel? _selectedFromStation;
  StationModel? _selectedToStation;

  List<Marker> _cachedMarkers = [];
  Map<String, LatLng> _activeBuses = {}; // bus_id -> position
  RealtimeChannel? _trackingChannel;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _busesSubscription?.cancel();
    _trackingChannel?.unsubscribe();
    _fromController.dispose();
    _toController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    // Prefetch all static data via UserDataManager
    await UserDataManager().prefetchData();
    _allStations = await UserDataManager().getStations();
    
    _loadInitialLocation();
    _setupRealtimeBuses();
    
    if (mounted) setState(() => _isLoading = false);

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

  void _setupRealtimeBuses() {
    _busesSubscription?.cancel();
    _busesSubscription = SupabaseConfig.client
        .from('buses')
        .stream(primaryKey: ['id'])
        .listen((data) {
          if (!mounted) return;
          for (final b in data) {
            final lat = b['current_lat'] ?? b['lat'];
            final lng = b['current_lng'] ?? b['lng'];
            if (lat != null && lng != null) {
              _activeBuses[b['id'].toString()] = LatLng((lat as num).toDouble(), (lng as num).toDouble());
            }
          }
          setState(() {
            _updateMarkers();
          });
        });

    _trackingChannel?.unsubscribe();
    _trackingChannel = SupabaseConfig.client.channel('public-tracking');
    _trackingChannel!.onBroadcast(
      event: 'bus_moved', 
      callback: (payload) {
        if (!mounted || payload == null) return;
        final busId = payload['bus_id']?.toString();
        final lat = payload['lat'];
        final lng = payload['lng'];
        
        if (busId != null && lat != null && lng != null) {
          setState(() {
            _activeBuses[busId] = LatLng((lat as num).toDouble(), (lng as num).toDouble());
            _updateMarkers();
          });
        }
      }
    ).subscribe();
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

  void _updateMarkers() {
    _cachedMarkers = [
      if (_userLocation != null) _buildUserLocationMarker(),
      ..._allStations.map((s) => _buildStationMarker(s)),
      ..._activeBuses.entries.map((e) => _buildBusMarker(e.key, e.value)),
    ];
  }

  Marker _buildBusMarker(String id, LatLng pos) => Marker(
    point: pos,
    width: 30,
    height: 30,
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B6A4C),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: const Icon(Icons.directions_bus, color: Colors.white, size: 16),
    ),
  );

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

  void _triggerRouteDrawing() async {
    if (_selectedFromStation == null || _selectedToStation == null) return;
    
    List<StationModel> zoneStations = _allStations.where((s) => s.zone == _selectedFromStation!.zone).toList();
    int startIndex = zoneStations.indexWhere((s) => s.id == _selectedFromStation!.id);
    int endIndex = zoneStations.indexWhere((s) => s.id == _selectedToStation!.id);
    if (startIndex == -1 || endIndex == -1) return;
    
    int actualStart = startIndex < endIndex ? startIndex : endIndex;
    int actualEnd = startIndex < endIndex ? endIndex : startIndex;
    List<StationModel> segment = zoneStations.sublist(actualStart, actualEnd + 1);
    if (startIndex > endIndex) segment = segment.reversed.toList();
    
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
      }
    } catch (e) {
      debugPrint("Routing Error: $e");
    }
  }

  Future<void> _handleFindTrip() async {
    if (_selectedFromStation == null || _selectedToStation == null) return;
    setState(() => _isSearching = true);
    
    try {
      final response = await _repository.getNearestBus(_selectedFromStation!.id);
      
      if (response == null || (response is List && response.isEmpty)) {
        throw Exception("No active buses available at the moment.");
      }
      
      final data = response is List ? response[0] : response;
      
      final String busNum = data['bus_number']?.toString() ?? data['busNumber']?.toString() ?? 'Unknown';
      final int eta = data['eta_minutes'] is int ? data['eta_minutes'] : int.tryParse(data['eta_minutes']?.toString() ?? '') ?? 5;
      
      List<StationModel> zoneStations = _allStations.where((s) => s.zone == _selectedFromStation!.zone).toList();
      int startIndex = zoneStations.indexWhere((s) => s.id == _selectedFromStation!.id);
      int endIndex = zoneStations.indexWhere((s) => s.id == _selectedToStation!.id);
      
      List<StationModel> allRouteStations = zoneStations;
      if (startIndex > endIndex) {
        allRouteStations = zoneStations.reversed.toList();
      }

      if (mounted) {
        final result = await Navigator.pushNamed(context, RoutesManager.busTracking, arguments: {
          'busId': data['id'] ?? data['bus_id'],
          'startStationId': _selectedFromStation!.id,
          'endStationId': _selectedToStation!.id,
          'from': _selectedFromStation!.name,
          'to': _selectedToStation!.name,
          'zone': _selectedFromStation!.zone,
          'busNumber': busNum,
          'arrivalTime': "$eta min",
          'distance': data['distanceToStationKm'] ?? data['distance_to_station_km'] ?? data['distance_km'],
          'stations': allRouteStations.map((s) => {'name': s.name, 'latLong': s.latLong, 'zone': s.zone}).toList(),
          'polylinePoints': _polylinePoints,
          'lat': data['current_lat'] ?? data['lat'],
          'lng': data['current_lng'] ?? data['lng'],
        });
        if (result == "OPEN_QR" && widget.onScanRequested != null) widget.onScanRequested!();
      }
    } catch (e) {
      if (mounted) {
         _showErrorDialog("Trip Notice", e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)), 
        contentPadding: EdgeInsets.all(20.w),
        content: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(color: const Color(0xFFFDF2F2), shape: BoxShape.circle),
              child: Icon(Icons.info_outline_rounded, color: const Color(0xFFE24B4A), size: 30.sp),
            ),
            SizedBox(height: 16.h), 
            Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)), 
            SizedBox(height: 10.h), 
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: Colors.grey[700], height: 1.4)), 
            SizedBox(height: 24.h), 
            SizedBox(
              width: double.infinity,
              height: 45.h,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context), 
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0XFF054F3A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))), 
                child: const Text("Got it", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const _StaticHeader(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading ? _buildSkeleton() : _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Stack(
      children: [
        SkeletonLoader(width: double.infinity, height: double.infinity),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30.r))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonLoader(width: 60.w, height: 20.h),
                SizedBox(height: 12.h),
                SkeletonLoader(width: double.infinity, height: 50.h, borderRadius: 12.r),
                SizedBox(height: 16.h),
                SkeletonLoader(width: 40.w, height: 20.h),
                SizedBox(height: 12.h),
                SkeletonLoader(width: double.infinity, height: 50.h, borderRadius: 12.r),
                SizedBox(height: 24.h),
                SkeletonLoader(width: double.infinity, height: 55.h, borderRadius: 15.r),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        _buildMap(),
        Positioned(
          top: 100.h,
          right: 20.w,
          child: _buildLocationButton(),
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: _buildSearchCard()),
      ],
    );
  }

  Widget _buildLocationButton() {
    return FloatingActionButton.small(
      onPressed: () {
        if (_userLocation != null) {
          _animatedMapMove(_userLocation!, 15.0);
        }
      },
      backgroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: const Icon(Icons.my_location, color: Color(0xFF1B6A4C)),
    );
  }

  Widget _buildMap() {
    return RepaintBoundary(
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
            tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 200)),
            retinaMode: RetinaMode.isHighDensity(context),
          ),
          if (_polylinePoints.isNotEmpty) 
            PolylineLayer(polylines: [
              Polyline(points: _polylinePoints, color: RouteModel.getColorFromName(_selectedFromStation?.zone ?? ""), strokeWidth: 4.0)
            ]),
          MarkerLayer(markers: _cachedMarkers),
        ],
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
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 15.h),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 15, offset: const Offset(0, -5))]),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
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
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _isSearching ? null : _handleFindTrip,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0XFF054F3A), minimumSize: Size(double.infinity, 50.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r))),
              child: _isSearching ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Trip & Bus", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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
        return Container(height: 0.8.sh, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25.r))), padding: EdgeInsets.all(20.w), child: Column(children: [Container(width: 40.w, height: 4.h, color: Colors.grey[300]), SizedBox(height: 20.h), const Text("Select Station", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), if (!isFrom && _selectedFromStation != null) Text("Route: ${_selectedFromStation!.zone}", style: TextStyle(color: RouteModel.getColorFromName(_selectedFromStation!.zone), fontSize: 13)), SizedBox(height: 15.h), TextField(controller: searchController, decoration: InputDecoration(hintText: "Search stations...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r))), onChanged: (value) => setModalState(() {})), Expanded(child: filtered.isEmpty ? const Center(child: Text("No stations found")) : ListView.builder(physics: const ClampingScrollPhysics(), itemCount: filtered.length, itemBuilder: (context, index) { 
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
          children: [
            // Logo Part
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Transit", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                Text("Way", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1B6A4C))),
                Icon(Icons.location_on, color: const Color(0xFF1B6A4C), size: 20.sp),
              ],
            ),
            
            const Spacer(),
            
            // Actions Part
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildConnectivityIndicator(),
                _buildNotificationIcon(context),
                const CustomPointsBadge(),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildConnectivityIndicator() {
    return StreamBuilder<bool>(
      stream: ConnectivityService().connectionStream,
      initialData: ConnectivityService().isOnline,
      builder: (context, snapshot) {
        final bool isOnline = snapshot.data ?? true;
        return Container(
          margin: EdgeInsets.only(right: 4.w),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOnline ? Icons.check_circle_outline : Icons.wifi_off_rounded, 
                color: isOnline ? Colors.green : Colors.red, 
                size: 12.sp
              ),
              SizedBox(width: 2.w),
              Text(
                isOnline ? "Online" : "Weak",
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.red,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return StreamBuilder<int>(
      stream: InAppNotificationService().unreadCountStream,
      builder: (context, snapshot) {
        int count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: Colors.black, size: 28.sp),
              onPressed: () => Navigator.pushNamed(context, RoutesManager.notifications),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                  child: Text(
                    count > 9 ? '+9' : count.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class SLineWidget extends StatelessWidget {
  final double width;
  const SLineWidget({super.key, required this.width});
  @override
  Widget build(BuildContext context) => SizedBox(width: width);
}
