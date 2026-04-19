import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/core/resources/color_manager.dart';
import 'package:transite_way/feature/driver/presentation/screens/add_tickets/add_tickets_screen.dart';
import 'package:transite_way/feature/driver/presentation/screens/home/widgets/home_widgets.dart';
import 'package:transite_way/feature/driver/presentation/screens/profile/profile_screen_driver.dart';
import 'package:transite_way/feature/driver/presentation/screens/routes/routes_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeTabBody(),
    AddTicketsScreen(),
    RoutesScreen(),
    ProfileScreenDriver(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ColorManager.white,
          border: Border(
            top: BorderSide(color: const Color(0xffDADADA), width: 2),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: ColorManager.white,
          selectedItemColor: ColorManager.lightGreen,
          unselectedItemColor: ColorManager.grey,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(fontSize: 11.sp),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
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
