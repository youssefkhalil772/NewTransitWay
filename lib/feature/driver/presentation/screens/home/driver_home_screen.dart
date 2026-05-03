import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/core/resources/color_manager.dart';
import 'package:transite_way/feature/driver/presentation/screens/add_tickets/add_tickets_screen.dart';
import 'package:transite_way/feature/driver/presentation/screens/home/widgets/home_widgets.dart';
import 'package:transite_way/feature/driver/presentation/screens/profile/profile_screen_driver.dart';
import 'package:transite_way/feature/driver/presentation/screens/qr/trip_qr_screen.dart';
import 'package:transite_way/feature/driver/presentation/screens/routes/routes_screen.dart';
import 'package:transite_way/feature/home/data/models/station_model.dart';
import 'package:transite_way/feature/home/presentation/widgets/custom_app_bar.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;
  int _routesRefreshKey = 0;
  List<StationModel> _currentTripStations = [];

  Future<void> _onTabChanged(int index, {List<StationModel>? stations}) async {
    if (index == 1 || index == 2) {
      final prefs = await SharedPreferences.getInstance();
      final isTripActive = prefs.getBool('isTripActive') ?? false;
      if (!isTripActive) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please start a trip first to access this feature'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      _selectedIndex = index;

      // لو فيه stations مبعوتة، ده معناه إننا بدأنا رحلة جديدة فعلاً من صفحة الـ Home
      if (stations != null) {
        _currentTripStations = stations;
        _routesRefreshKey++; // بنزود الـ Key هنا بس عشان نصفر حالة الخريطة للرحلة الجديدة
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // استخدمنا IndexedStack عشان يحافظ على حالة الصفحات في الذاكرة وميعدش بنائهم
    final List<Widget> pages = [
      HomeTabBody(
        onStartTrip: (stations) => _onTabChanged(3, stations: stations),
      ),
      const TripQrScreen(isTab: true),
      const AddTicketsScreen(isTab: true),
      RoutesScreen(
        onEndTrip: () => _onTabChanged(0),
        onGoHome: () => _onTabChanged(0),
        isTab: true,
        refreshTrigger: _routesRefreshKey,
        stations: _currentTripStations,
      ),
      ProfileScreenDriver(isTab: true, onAddTicketsTap: () => _onTabChanged(2)),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? null
          : CustomAppBar(isDriver: true, showPoints: false),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ColorManager.white,
          border: const Border(
            top: BorderSide(color: Color(0xffDADADA), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => _onTabChanged(i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: ColorManager.white,
          selectedItemColor: const Color(0xFF39C449),
          unselectedItemColor: ColorManager.grey,
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
          ),
          unselectedLabelStyle: TextStyle(fontSize: 11.sp),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_outlined),
              activeIcon: Icon(Icons.qr_code),
              label: 'Trip QR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              activeIcon: Icon(Icons.confirmation_number),
              label: 'Add Tickets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Routes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
