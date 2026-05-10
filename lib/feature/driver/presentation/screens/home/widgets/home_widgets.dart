import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/core/networking/supabase_init.dart';
import 'package:transite_way/core/networking/api_constants.dart';
import 'package:transite_way/feature/driver/data/driver_auth_service.dart';
import 'package:transite_way/feature/tracking/data/tracking_service.dart';

import 'package:transite_way/feature/home/data/models/station_model.dart';
import 'package:transite_way/feature/home/data/models/route_model.dart';
import 'package:transite_way/feature/driver/presentation/screens/widgets/skeleton_loader.dart';
import 'package:transite_way/feature/driver/data/driver_data_manager.dart';
import 'package:transite_way/core/networking/connectivity_service.dart';
import '../../../../../../core/resources/color_manager.dart';
import 'package:transite_way/core/widgets/swipe_to_confirm.dart';

class HomeTabBody extends StatefulWidget {
  final Function(List<StationModel> stations) onStartTrip;
  const HomeTabBody({super.key, required this.onStartTrip});

  @override
  State<HomeTabBody> createState() => _HomeTabBodyState();
}

class _HomeTabBodyState extends State<HomeTabBody> {
  final DriverAuthServices _driverService = DriverAuthServices();
  final TrackingService _trackingService = TrackingService();


  String _driverName = "Loading...";
  String _busNumber = "---";
  String _plateNumber = "---";
  String _routeName = "---";
  int _stationsCount = 0;
  List<StationModel> _routeStations = [];
  bool _isLoading = true;
  bool _isStartingTrip = false;
  StreamSubscription? _busSubscription;

  @override
  void initState() {
    super.initState();
    _loadAllData().then((_) => _setupRealtime());
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    _trackingService.stopTracking();
    super.dispose();
  }

  void _setupRealtime() {
    final currentDriverId = SupabaseConfig.client.auth.currentUser?.id;
    if (currentDriverId == null) return;

    _busSubscription?.cancel();
    _busSubscription = SupabaseConfig.client
        .from(ApiConstants.busesTable)
        .stream(primaryKey: ['id'])
        .eq('driver_id', currentDriverId)
        .listen((data) {
          if (data.isNotEmpty && !_isLoading) {
            debugPrint("🔄 HomeTab: Realtime update triggered");
            _loadAllData();
          }
        });
  }

  bool _isBusAssigned = false;
  bool _isRouteAssigned = false;

  Future<void> _loadAllData() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      final currentDriverId = SupabaseConfig.client.auth.currentUser?.id;

      if (currentDriverId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Always load driver name first regardless of bus assignment
      final driverData = await _driverService.getDriverData(currentDriverId);
      final String driverName = driverData['full_name'] ?? driverData['name'] ?? 'Driver';

      final busData = await SupabaseConfig.client
          .from(ApiConstants.busesTable)
          .select('*')
          .eq('driver_id', currentDriverId)
          .maybeSingle();

      if (busData == null) {
        // No bus assigned to this driver
        if (mounted) {
          setState(() {
            _driverName = driverName;
            _busNumber = 'Not Assigned';
            _plateNumber = 'Not Assigned';
            _routeName = 'Not Assigned';
            _stationsCount = 0;
            _isBusAssigned = false;
            _isRouteAssigned = false;
            _isLoading = false;
          });
        }
        return;
      }

      // Bus found — now check route
      // Force clear cache to always get fresh data from DB
      DriverDataManager().clearCache();
      await DriverDataManager().prefetchData();
      final allRoutes = await DriverDataManager().getRoutes();
      final allStations = await DriverDataManager().getStations();

      final int? oldRouteId = busData['route_id'] as int?;
      final int? lineNumber = int.tryParse(busData['route_name']?.toString() ?? '');
      debugPrint('🚌 Bus route_id: $oldRouteId, route_name (lineNumber): $lineNumber');
      debugPrint('📋 Available lines: ${allRoutes.map((r) => "id=${r.id} name=${r.name}").toList()}');

      // Try matching route by line_number (which is mapped to RouteModel.id)
      RouteModel? matchedRoute;
      if (lineNumber != null) {
        try {
          matchedRoute = allRoutes.firstWhere((r) => r.id == lineNumber);
          debugPrint('✅ Route matched: ${matchedRoute.name}');
        } catch (_) {
          debugPrint('❌ No route found with line_number=$lineNumber in ${allRoutes.length} lines');
          matchedRoute = null;
        }
      } else {
        debugPrint('⚠️ bus has invalid or null route_name');
      }

      final bool routeAssigned = matchedRoute != null;

      if (routeAssigned) {
        final rZone = matchedRoute!.zone.toLowerCase().replaceAll(' ', '');
        _routeStations = allStations
            .where((s) => s.zone.toLowerCase().replaceAll(' ', '') == rZone)
            .toList();
      } else {
        _routeStations = [];
      }

      try {
        await SupabaseConfig.client
            .from('drivers')
            .update({'bus_id': busData['id']})
            .eq('id', currentDriverId);
      } catch (_) {}

      await prefs.setString('busId', busData['id'].toString());
      if (routeAssigned) await prefs.setInt('routeId', matchedRoute.id);
      await prefs.setString('busNumber', busData['bus_number']?.toString() ?? '---');
      if (routeAssigned) {
        final double price = matchedRoute.price > 0 ? matchedRoute.price : 30.0;
        await prefs.setDouble('ticketPrice', price);
      }

      // Check active trip
      final activeTrip = await SupabaseConfig.client
          .from('trips')
          .select('id')
          .eq('bus_id', busData['id'])
          .isFilter('ended_at', null)
          .maybeSingle();

      await prefs.setBool('isTripActive', activeTrip != null);

      if (mounted) {
        setState(() {
          _driverName = driverName;
          _busNumber = busData['bus_number']?.toString() ?? '---';
          _plateNumber = busData['plate_number']?.toString() ?? '---';
          _routeName = routeAssigned ? matchedRoute!.name : 'No Route Assigned';
          _stationsCount = _routeStations.length;
          _isBusAssigned = true;
          _isRouteAssigned = routeAssigned;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ HomeTab _loadAllData error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStartTrip() async {
    final prefs = await SharedPreferences.getInstance();
    String? busId = prefs.getString('busId');
    if (busId == null || busId.isEmpty) return;

    bool hasPermission = await _trackingService.checkPermissions();
    if (!hasPermission) return;

    setState(() => _isStartingTrip = true);

    try {
      await _trackingService.startTrip(busId);
      await prefs.setBool('isTripActive', true);

      if (mounted) {
        widget.onStartTrip(_routeStations);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to start trip: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingTrip = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading ? _buildSkeleton() : _buildContent(),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      key: const ValueKey('skeleton'),
      child: Column(
        children: [
          Container(
            height: 180.h,
            decoration: BoxDecoration(
              color: ColorManager.grey2,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50.r),
                bottomRight: Radius.circular(50.r),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 26),
                      SizedBox(width: 8.w),
                      const SkeletonLoader(width: 150, height: 20),
                    ],
                  ),
                  SizedBox(height: 29.h),
                  const SkeletonLoader(width: 200, height: 30),
                  SizedBox(height: 8.h),
                  const SkeletonLoader(width: 120, height: 16),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 30.h),
            child: Column(
              children: List.generate(
                4,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: 15.h),
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 75.h,
                    borderRadius: 10.r,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: _loadAllData,
      color: ColorManager.lightGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: ColorManager.grey2,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isRouteAssigned ? Icons.location_on_outlined : Icons.location_off_outlined,
                          size: 26,
                          color: _isRouteAssigned ? Colors.black : Colors.orange,
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            _routeName,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _isRouteAssigned ? Colors.black : Colors.orange,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        _buildConnectivityIndicator(),
                        IconButton(
                          onPressed: _loadAllData,
                          icon: Icon(Icons.refresh, size: 22.sp, color: Colors.black87),
                          tooltip: 'Reload',
                        ),
                      ],
                    ),
                    const SizedBox(height: 29),
                    Text(
                      'Hello $_driverName!',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _isBusAssigned ? 'Start your trip now' : 'No bus assigned to your account yet',
                      style: TextStyle(color: _isBusAssigned ? Colors.grey : Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 30.h),
              child: Column(
                children: [
                  InfoCard(label: 'Bus Number', value: _busNumber),
                  SizedBox(height: 15.h),
                  InfoCard(label: 'Plate Number', value: _plateNumber),
                  SizedBox(height: 15.h),
                  InfoCard(label: 'Route Name', value: _routeName),
                  SizedBox(height: 15.h),
                  InfoCard(label: 'Number Of Stations', value: '$_stationsCount'),
                ],
              ),
            ),
            // Only show swipe button if bus AND route are assigned
            if (_isBusAssigned && _isRouteAssigned)
              Padding(
                padding: EdgeInsets.all(30.w),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F0E5),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    children: [
                      const Text('Trip tracking is ready',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(height: 16.h),
                      SwipeToConfirm(
                        text: "SWIPE TO START TRIP",
                        onConfirm: _handleStartTrip,
                        isLoading: _isStartingTrip,
                        baseColor: ColorManager.lightGreen,
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isBusAssigned ? 'No Route Assigned' : 'No Bus Assigned',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _isBusAssigned
                                  ? 'Ask your admin to assign a route to your bus before starting a trip.'
                                  : 'Ask your admin to assign a bus to your driver account.',
                              style: TextStyle(fontSize: 12.sp, color: Colors.orange.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 20.h),
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
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOnline ? Icons.check_circle_outline : Icons.wifi_off_rounded, 
                color: isOnline ? Colors.green : Colors.red, 
                size: 12.sp
              ),
              SizedBox(width: 3.w),
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
}

class InfoCard extends StatelessWidget {
  final String label, value;
  const InfoCard({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: ColorManager.grey4, width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
          ),
          SizedBox(height: 5.h),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: ColorManager.lightGreen,
            ),
          ),
        ],
      ),
    );
  }
}
