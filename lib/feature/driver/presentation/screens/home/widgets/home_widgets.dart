import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/core/networking/supabase_init.dart';
import 'package:transite_way/core/networking/api_constants.dart';
import 'package:transite_way/feature/driver/data/driver_auth_service.dart';
import 'package:transite_way/feature/tracking/data/tracking_service.dart';
import 'package:transite_way/feature/home/data/home_repository.dart';
import 'package:transite_way/feature/home/data/models/station_model.dart';
import 'package:transite_way/feature/home/data/models/route_model.dart';
import '../../../../../../core/resources/color_manager.dart';

class HomeTabBody extends StatefulWidget {
  final Function(List<StationModel> stations) onStartTrip;
  const HomeTabBody({super.key, required this.onStartTrip});

  @override
  State<HomeTabBody> createState() => _HomeTabBodyState();
}

class _HomeTabBodyState extends State<HomeTabBody> {
  final DriverAuthServices _driverService = DriverAuthServices();
  final HomeRepository _homeRepository = HomeRepository();
  final TrackingService _trackingService = TrackingService();

  String _driverName = "Loading...";
  String _busNumber = "---";
  String _plateNumber = "---";
  String _routeName = "---";
  int _stationsCount = 0;
  List<StationModel> _routeStations = [];
  bool _isLoading = true;
  bool _isStartingTrip = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _trackingService.stopTracking();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. بنجيب الـ ID بتاع السواق اللي عامل تسجيل دخول (حسن)
      final currentDriverId = SupabaseConfig.client.auth.currentUser?.id;
      
      if (currentDriverId != null) {
        // 2. بنروح جدول الباصات وندور على الباص المربوط بالـ ID ده
        final busData = await SupabaseConfig.client
            .from(ApiConstants.busesTable)
            .select('*') // هنسحب كل بيانات الباص
            .eq('driver_id', currentDriverId)
            .maybeSingle();

        // نحمل باقي البيانات الأساسية للتطبيق
        final results = await Future.wait([
          _driverService.getDriverData(currentDriverId),
          _homeRepository.getRoutes(),
          _homeRepository.getStations(),
        ]);

        final driverData = results[0] as Map<String, dynamic>;
        final allRoutes = results[1] as List<RouteModel>;
        final allStations = results[2] as List<StationModel>;

        if (busData != null) {
          // نجيب الـ route_id الحقيقي المربوط بالباص
          final int? routeId = busData['route_id'] as int?;

          // نطابق المسار بناءً على الـ ID الدقيق
          final matchedRoute = allRoutes.firstWhere(
            (RouteModel r) => routeId != null && r.id == routeId,
            orElse: () => allRoutes.isNotEmpty ? allRoutes.first : RouteModel(id: 0, name: 'No Route', zone: 'Unknown', color: Colors.grey, price: 30.0),
          );

          // نصفي المحطات
          _routeStations = allStations
              .where((s) => s.zone.toLowerCase().trim() == matchedRoute.zone.toLowerCase().trim())
              .toList();

          // نحفظ البيانات في الـ SharedPreferences عشان باقي الأبلكيشن
          await prefs.setString('busId', busData['id'].toString());
          await prefs.setInt('routeId', matchedRoute.id);
          await prefs.setString('busNumber', busData['bus_number']?.toString() ?? '---');
          
          // نسحب السعر مباشرة من الموديل اللي أخدناه من جدول routes
          final double price = matchedRoute.price > 0 ? matchedRoute.price : 30.0;
          await prefs.setDouble('ticketPrice', price);

          if (mounted) {
            setState(() {
              // هنا هنربط المتغيرات بتاعتك في التصميم بالداتا اللي راجعة
              _driverName = driverData['full_name'] ?? driverData['name'] ?? 'Driver';
              _busNumber = busData['bus_number']?.toString() ?? '---';
              _plateNumber = busData['plate_number']?.toString() ?? '---';
              _routeName = matchedRoute.name;
              _stationsCount = _routeStations.length;
              _isLoading = false;
            });
          }
        } else {
          // لو ملوش باص هيطلع الإيرور الأحمر اللي في الصورة
          debugPrint('Error: Bus ID not found!');
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        debugPrint('Error: User not logged in!');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching bus: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStartTrip() async {
    final prefs = await SharedPreferences.getInstance();
    String? busId = prefs.getString('busId');
    if (busId == null || busId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Bus ID not found!"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    bool hasPermission = await _trackingService.checkPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied!"), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() => _isStartingTrip = true);

    try {
      await _trackingService.startTrip(busId);
      await prefs.setBool('isTripActive', true);
      
      if (mounted) {
        widget.onStartTrip(_routeStations);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Trip Started Successfully! Bus #$_busNumber"), 
            backgroundColor: Colors.green, 
            behavior: SnackBarBehavior.floating
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to start trip: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingTrip = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Colors.green)));

    return SafeArea(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: ColorManager.grey2, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50))),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Icon(Icons.location_on_outlined, size: 26), SizedBox(width: 8.w), Expanded(child: Text(_routeName, style: const TextStyle(fontWeight: FontWeight.w500)))]),
                  const SizedBox(height: 29),
                  Text('Hello $_driverName!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  const Text('Start your trip now', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 30.h),
                    child: Column(children: [
                      InfoCard(label: 'Bus Number', value: _busNumber),
                      SizedBox(height: 15.h),
                      InfoCard(label: 'Plate Number', value: _plateNumber),
                      SizedBox(height: 15.h),
                      InfoCard(label: 'Route Name', value: _routeName),
                      SizedBox(height: 15.h),
                      InfoCard(label: 'Number Of Stations', value: '$_stationsCount'),
                    ]),
                  ),
                  Padding(
                    padding: EdgeInsets.all(30.w),
                    child: Container(
                      width: double.infinity, padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(color: const Color(0xFFE2F0E5), borderRadius: BorderRadius.circular(10.r)),
                      child: Column(children: [
                        const Text('Trip tracking is ready', style: TextStyle(fontWeight: FontWeight.w500)),
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity, 
                          height: 50.h, 
                          child: ElevatedButton(
                            onPressed: _isStartingTrip ? null : _handleStartTrip, 
                            style: ElevatedButton.styleFrom(backgroundColor: ColorManager.lightGreen), 
                            child: _isStartingTrip 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Start Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                          )
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String label, value;
  const InfoCard({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: ColorManager.grey4, width: 2)),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700)),
        SizedBox(height: 5.h),
        Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: ColorManager.lightGreen)),
      ]),
    );
  }
}
