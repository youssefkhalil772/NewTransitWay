import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../profile/profile_screen.dart'; 
import '../../../qr_scanner/success_dialog.dart';
import '../../../tickets/tickets.dart';
import '../screens/home_screen.dart';
import 'custom_points_badge.dart'; // Used to update balance
import '../../../notifications/data/notification_service.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  String? _userId;
  int _ticketsRefreshKey = 0;
  int _qrRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
    // Start listening to realtime notifications and ban status
    InAppNotificationService().startMonitoring();

    // Update balance on app open
    CustomPointsBadge.fetchAndRefreshGlobalBalance();
  }

  List<Widget> _pages() => [
    const HomeScreen(),
    MyTicketsScreen(
      userId: _userId,
      refreshTrigger: _ticketsRefreshKey,
      onBackToHome: () => setState(() => _selectedIndex = 0),
    ),
    QRScannerPage(
      key: _selectedIndex == 2 ? ValueKey('qr_active_$_qrRefreshKey') : const ValueKey('qr_inactive'),
      isActive: _selectedIndex == 2,
      onBackToHome: () => setState(() => _selectedIndex = 0),
      onViewTickets: () {
        setState(() {
          _selectedIndex = 1;
          _ticketsRefreshKey++;
        });
      },
    ),
    ProfileScreen(
      onViewTickets: () {
        setState(() {
          _selectedIndex = 1;
          _ticketsRefreshKey++;
        });
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 1) _ticketsRefreshKey++;
            if (index == 2) _qrRefreshKey++;
          });
          // Update balance automatically every time the user changes the tab
          // This ensures that if the admin changes something, the user sees it immediately
          CustomPointsBadge.fetchAndRefreshGlobalBalance();
        },
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
