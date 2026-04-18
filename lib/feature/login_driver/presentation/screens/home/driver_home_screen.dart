import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/core/resources/color_manager.dart';
import 'package:transite_way/core/routes/routes_manager.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _HomeTab(),
    _AddTicketsTab(),
    _RoutesTab(),
    _ProfileTab(),
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

// ====================== Home Tab ======================
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 26,
                        color: ColorManager.black,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Alf Maskan - Gesr El Suez',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: ColorManager.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 29),
                  Text(
                    'Hello Sayed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.black,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Start your trip now',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: ColorManager.grey3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(50),
                    child: Column(
                      children: [
                        _InfoCard(label: 'Bus Number', value: '345'),
                        SizedBox(height: 20),
                        _InfoCard(label: 'Route Number', value: '14'),
                        SizedBox(height: 20),
                        _InfoCard(label: 'Number Of Stations', value: '35'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F0E5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Start trip from 9:00 AM to 3:00 PM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: ColorManager.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorManager.lightGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Start Trip',
                                style: TextStyle(
                                  color: ColorManager.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: ColorManager.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColorManager.grey4, width: 3),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: ColorManager.black),
          ),
          const SizedBox(height: 11),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorManager.lightGreen,
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== Add Tickets Tab ======================
class _AddTicketsTab extends StatelessWidget {
  const _AddTicketsTab();

  static const List<Map<String, String>> _tickets = [
    {'bus': '359', 'price': '35', 'time': '9:00 pm', 'date': '25-2-2026'},
    {'bus': '009', 'price': '35', 'time': '1:30 pm', 'date': '2-2-2026'},
    {'bus': '117', 'price': '15', 'time': '7:00 am', 'date': '21-1-2026'},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            color: ColorManager.white,
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
            child: Row(
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Transit',
                        style: TextStyle(
                          color: ColorManager.black,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: 'Way',
                        style: TextStyle(
                          color: ColorManager.lightGreen,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(Icons.location_on, color: ColorManager.lightGreen, size: 24.sp),
                SizedBox(width: 6.w),
                Text(
                  'Driver',
                  style: TextStyle(fontSize: 20.sp, color: ColorManager.black),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              children: [
                ..._tickets.map(
                      (t) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: TicketCard(
                      busNumber: t['bus']!,
                      price: t['price']!,
                      time: t['time']!,
                      date: t['date']!,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "User doesn't have an account?",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: ColorManager.black,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.lightGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Add Ticket Here !',
                            style: TextStyle(
                              color: ColorManager.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== Ticket Card ======================
class TicketCard extends StatelessWidget {
  final String busNumber, price, time, date;

  const TicketCard({
    super.key,
    required this.busNumber,
    required this.price,
    required this.time,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF054F3A).withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSideLabel(),
            _buildTicketDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildSideLabel() {
    return SizedBox(
      width: 48.w,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: DottedVerticalLinePainter()),
          Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'هيئة النقل العام',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'بالقاهرة',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

  Widget _buildTicketDetails() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 14.h, 16.w, 14.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Bus:', busNumber),
                  SizedBox(height: 8.h),
                  _buildInfoRow('Price:', '$price EGP'),
                  SizedBox(height: 8.h),
                  _buildInfoRow('Time:', time),
                  SizedBox(height: 8.h),
                  _buildInfoRow('Date:', date),
                ],
              ),
            ),
            _buildLogos(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogos() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Transit',
                    style: TextStyle(
                      color: ColorManager.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'Way',
                    style: TextStyle(
                      color: ColorManager.lightGreen,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.location_on_outlined,
              size: 17.sp,
              color: ColorManager.lightGreen,
            ),
          ],
        ),
         SizedBox(height: 40),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber.withOpacity(0.2), width: 1),
          ),
          child: Image.asset('assets/logo/2.png', width: 63.w, height: 58.h),
        ),
      ],
    );
  }
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ====================== Dotted Line Painter ======================
class DottedVerticalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF054F3A).withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashHeight = 6.0;
    const dashSpace = 6.0;
    double startY = 0.0;
    final xPosition = size.width / 1;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(xPosition, startY),
        Offset(xPosition, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ====================== باقي الـ Tabs ======================
class _RoutesTab extends StatelessWidget {
  const _RoutesTab();
  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text('Routes')));
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ElevatedButton(
          onPressed: () =>
              RoutesManager.navigateTo(context, RoutesManager.profile),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorManager.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(
            'Go to Profile',
            style: TextStyle(color: ColorManager.white, fontSize: 14.sp),
          ),
        ),
      ),
    );
  }
}