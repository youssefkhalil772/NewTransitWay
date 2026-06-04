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
import 'package:visibility_detector/visibility_detector.dart';

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
  bool _hasActiveTrip = false;
  StreamSubscription? _driverSubscription;
  StreamSubscription? _busSubscription;
  StreamSubscription? _tripSubscription;

  String? _lastDriverBusId;
  String? _lastBusRouteId;
  String? _lastBusPlate;

  @override
  void initState() {
    super.initState();
    _loadAllData().then((_) => _setupRealtime());
  }

  @override
  void dispose() {
    _driverSubscription?.cancel();
    _busSubscription?.cancel();
    _tripSubscription?.cancel();
    _trackingService.stopTracking();
    super.dispose();
  }

  void _setupRealtime() async {
    final currentDriverId = SupabaseConfig.client.auth.currentUser?.id;
    if (currentDriverId == null) return;

    _driverSubscription?.cancel();
    _driverSubscription = SupabaseConfig.client
        .from(ApiConstants.driversTable)
        .stream(primaryKey: ['id'])
        .eq('id', currentDriverId)
        .listen((data) {
          if (data.isNotEmpty && mounted && !_isLoading) {
            final driver = data.first;
            final newBusId = driver['busId']?.toString();

            if (newBusId != _lastDriverBusId) {
              _lastDriverBusId = newBusId;
              debugPrint('ðŸ”„ HomeTab: Driver row changed â†’ reloading');
              _loadAllData();
            }
          }
        });

    final prefs = await SharedPreferences.getInstance();
    final busId = prefs.getString('busId');

    if (busId != null && busId.isNotEmpty) {
      _busSubscription?.cancel();
      _busSubscription = SupabaseConfig.client
          .from('buses')
          .stream(primaryKey: ['id'])
          .eq('id', busId)
          .listen((data) {
            if (data.isNotEmpty && !_isLoading) {
              final bus = data.first;
              final bRouteId = bus['route_id']?.toString();
              final bPlate = bus['plate_number']?.toString();

              bool changed = false;
              if (_lastBusRouteId != null && bRouteId != _lastBusRouteId)
                changed = true;
              if (_lastBusPlate != null && bPlate != _lastBusPlate)
                changed = true;

              _lastBusRouteId = bRouteId;
              _lastBusPlate = bPlate;

              if (changed) {
                debugPrint(
                  "ðŸ”„ HomeTab: Bus Details Realtime update triggered",
                );
                _loadAllData();
              }
            }
          });

      _tripSubscription?.cancel();
      _tripSubscription = SupabaseConfig.client
          .from('trips')
          .stream(primaryKey: ['id'])
          .eq('bus_id', busId)
          .listen((data) {
            if (data.isNotEmpty) {
              final activeTrip = data.firstWhere(
                (trip) => trip['end_time'] == null,
                orElse: () => <String, dynamic>{},
              );
              final bool isActive = activeTrip.isNotEmpty;

              if (mounted && _hasActiveTrip != isActive) {
                debugPrint(
                  "ðŸ”„ HomeTab: Trip Realtime update triggered: $isActive",
                );
                prefs.setBool('isTripActive', isActive);
                setState(() {
                  _hasActiveTrip = isActive;
                });
              }
            }
          });
    }
  }

  bool _isBusAssigned = false;
  bool _isRouteAssigned = false;

  Future<void> _loadAllData() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      DriverDataManager().clearCache(); // Force fresh data

      final prefs = await SharedPreferences.getInstance();
      final currentDriverId = SupabaseConfig.client.auth.currentUser?.id;

      if (currentDriverId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      String driverName = 'Driver';
      try {
        final driverData = await _driverService.getDriverData(currentDriverId);
        driverName = driverData['full_name'] ?? driverData['name'] ?? 'Driver';
      } catch (e) {
        driverName = prefs.getString('driverName') ?? 'Driver';
        debugPrint(
          'âš ï¸ Could not load driver data from DB, using cached: $driverName',
        );
      }

      final currentEmail = SupabaseConfig.client.auth.currentUser?.email;

      Map<String, dynamic>? driverDbData;
      try {
        final resId = await SupabaseConfig.client
            .from(ApiConstants.driversTable)
            .select('*')
            .eq('id', currentDriverId)
            .limit(1);
        if (resId.isNotEmpty) driverDbData = resId.first;

        if (driverDbData == null && currentEmail != null) {
          final resEmail = await SupabaseConfig.client
              .from(ApiConstants.driversTable)
              .select('*')
              .eq('email', currentEmail)
              .limit(1);
          if (resEmail.isNotEmpty) driverDbData = resEmail.first;
        }
      } catch (e) {
        debugPrint('âš ï¸ Error fetching driverDbData: $e');
      }

      final String? assignedBusId = driverDbData?['busId']?.toString();

      Map<String, dynamic>? busData;
      try {
        if (assignedBusId != null && assignedBusId.isNotEmpty) {
          final resBusId = await SupabaseConfig.client
              .from(ApiConstants.busesTable)
              .select('*')
              .eq('id', assignedBusId)
              .limit(1);
          if (resBusId.isNotEmpty) busData = resBusId.first;
        } else {
          final resDriverId = await SupabaseConfig.client
              .from(ApiConstants.busesTable)
              .select('*')
              .eq('driver_id', currentDriverId)
              .limit(1);
          if (resDriverId.isNotEmpty) busData = resDriverId.first;
        }
      } catch (e) {
        debugPrint('âš ï¸ Error fetching busData: $e');
      }

      if (busData == null) {
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

      DriverDataManager().clearCache();
      await DriverDataManager().prefetchData();
      final allRoutes = await DriverDataManager().getRoutes();
      final allStations = await DriverDataManager().getStations();

      final String? oldRouteId = busData!['route_id']?.toString();
      final String? busRouteName = busData!['route_name']?.toString();
      debugPrint('ðŸšŒ Bus route_id: $oldRouteId, route_name: $busRouteName');
      debugPrint(
        'ðŸ“‹ Available lines: ${allRoutes.map((r) => "id=${r.id} name=${r.name}").toList()}',
      );

      RouteModel? matchedRoute;
      if (busRouteName != null && busRouteName.isNotEmpty) {
        try {
          matchedRoute = allRoutes.firstWhere((r) => r.name == busRouteName);
          debugPrint('âœ… Route matched: ${matchedRoute.name}');
        } catch (_) {
          debugPrint(
            'âŒ No route found with name=$busRouteName in ${allRoutes.length} lines',
          );
          matchedRoute = null;
        }
      } else {
        debugPrint('âš ï¸ bus has invalid or null route_name');
      }

      final bool routeAssigned = matchedRoute != null;

      if (routeAssigned && busData!['route_id'] != null) {
        try {
          final resStations = await SupabaseConfig.client
              .from('stations')
              .select('*')
              .eq('route_id', busData['route_id'])
              .order('order_index', ascending: true);
          _routeStations = resStations
              .map<StationModel>((json) => StationModel.fromJson(json))
              .toList();
          debugPrint(
            'ðŸ“ Loaded ${_routeStations.length} stations for route ${busData['route_id']}',
          );
        } catch (e) {
          debugPrint('âš ï¸ Error loading stations by route_id: $e');
          _routeStations = [];
        }
      } else {
        _routeStations = [];
      }

      try {
        final targetDriverId = driverDbData?['id'] ?? currentDriverId;
        await SupabaseConfig.client
            .from('drivers')
            .update({'bus_id': busData!['id']})
            .eq('id', targetDriverId);
      } catch (_) {}

      await prefs.setString('busId', busData!['id'].toString());
      if (routeAssigned && matchedRoute != null)
        await prefs.setInt('routeId', matchedRoute.id);
      await prefs.setString(
        'busNumber',
        busData!['bus_number']?.toString() ?? '---',
      );
      if (routeAssigned) {
        final double price = matchedRoute.price > 0 ? matchedRoute.price : 30.0;
        await prefs.setDouble('ticketPrice', price);
      }

      bool hasActiveTrip = false;
      try {
        final activeTripRes = await SupabaseConfig.client
            .from('trips')
            .select('id')
            .eq('bus_id', busData!['id'])
            .isFilter('end_time', null)
            .limit(1);
        hasActiveTrip = activeTripRes.isNotEmpty;
      } catch (_) {}

      await prefs.setBool('isTripActive', hasActiveTrip);

      if (mounted) {
        setState(() {
          _driverName = driverName;
          _busNumber = busData!['bus_number']?.toString() ?? '---';
          _plateNumber = busData!['plate_number']?.toString() ?? '---';
          _routeName = routeAssigned ? matchedRoute!.name : 'No Route Assigned';
          _stationsCount = _routeStations.length;
          _isBusAssigned = true;
          _isRouteAssigned = routeAssigned;
          _hasActiveTrip = hasActiveTrip;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('âŒ HomeTab _loadAllData error: $e');
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
        setState(() => _hasActiveTrip = true);
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

  Future<void> _checkTripStateSilently() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isTripActive = prefs.getBool('isTripActive') ?? false;
      if (mounted && _hasActiveTrip != isTripActive) {
        setState(() {
          _hasActiveTrip = isTripActive;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const ValueKey('home_tab_visibility'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction == 1.0) {
          _checkTripStateSilently();
        }
      },
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isLoading ? _buildSkeleton() : _buildContent(),
        ),
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
                          _isRouteAssigned
                              ? Icons.location_on_outlined
                              : Icons.location_off_outlined,
                          size: 26,
                          color: _isRouteAssigned
                              ? Colors.black
                              : Colors.orange,
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            _routeName,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _isRouteAssigned
                                  ? Colors.black
                                  : Colors.orange,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        _buildConnectivityIndicator(),
                        IconButton(
                          onPressed: _loadAllData,
                          icon: Icon(
                            Icons.refresh,
                            size: 22.sp,
                            color: Colors.black87,
                          ),
                          tooltip: 'Reload',
                        ),
                      ],
                    ),
                    const SizedBox(height: 29),
                    Text(
                      'Hello $_driverName!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _isBusAssigned
                          ? 'Start your trip now'
                          : 'No bus assigned to your account yet',
                      style: TextStyle(
                        color: _isBusAssigned ? Colors.grey : Colors.orange,
                      ),
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
                  InfoCard(
                    label: 'Number Of Stations',
                    value: '$_stationsCount',
                  ),
                ],
              ),
            ),
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
                      Text(
                        _hasActiveTrip
                            ? 'You have an active trip'
                            : 'Trip tracking is ready',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 16.h),
                      if (_hasActiveTrip)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => widget.onStartTrip(_routeStations),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorManager.lightGreen,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Go to Active Trip',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        )
                      else
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
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 28.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isBusAssigned
                                  ? 'No Route Assigned'
                                  : 'No Bus Assigned',
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
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.orange.shade700,
                              ),
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
            color: isOnline
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOnline ? Icons.check_circle_outline : Icons.wifi_off_rounded,
                color: isOnline ? Colors.green : Colors.red,
                size: 12.sp,
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
