import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../profile/profile_screen.dart';
import '../../../qr_scanner/success_dialog.dart';
import '../../../tickets/tickets.dart';
import '../screens/home_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    const HomeScreen(),
    // شاشة التذاكر
    MyTicketsScreen(
      onBackToHome: () => setState(() => _selectedIndex = 0),
    ),
    // شاشة الـ QR
    QRScannerPage(
      key: _selectedIndex == 2 ? UniqueKey() : null,
      isActive: _selectedIndex == 2,
      onBackToHome: () => setState(() => _selectedIndex = 0),
      onViewTickets: () => setState(() => _selectedIndex = 1),
    ),
    // شاشة البروفايل
    ProfileScreen(
      onViewTickets: () => setState(() => _selectedIndex = 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1B6A4C),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), activeIcon: Icon(Icons.confirmation_number), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), activeIcon: Icon(Icons.qr_code_scanner_sharp), label: 'Scan QR'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}