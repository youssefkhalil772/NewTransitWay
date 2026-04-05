import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const Color white = Color(0xFFFFFFFF);
const Color darkGreen = Color(0xFF00661B);

class PointsScreen extends StatelessWidget {
  final int pointsAdded;
  const PointsScreen({super.key, this.pointsAdded = 100});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Charge My Points',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20.h),

          // ── Step Indicator ──────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.w),
            child: Row(
              children: [
                _StepCircle(number: 1, isActive: true),
                _StepLine(),
                _StepCircle(number: 2, isActive: true),
                _StepLine(),
                _StepCircle(number: 3, isActive: true),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          // ── Illustration ────────────────────────────────────────
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              decoration: BoxDecoration(
                // color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/payment.png',
                   height: 332,
                  width: 375,
                  fit: BoxFit.none,
                ),
              ),
            ),
          ),

          SizedBox(height: 28.h),

          // ── Payment Successful Text ─────────────────────────────
          Text(
            'Payment Successful!',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),

          SizedBox(height: 10.h),

          Text(
            'Added $pointsAdded Point To Your Balance',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade500,
            ),
          ),

          SizedBox(height: 28.h),

          // ── Back To Home Button ─────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                      (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  foregroundColor: white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Back To Home',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),
        ],
      ),

      // ── Bottom Nav ──────────────────────────────────────────────
      bottomNavigationBar: _BottomNav(currentIndex: 3),
    );
  }
}

// ── Step Circle ───────────────────────────────────────────────────
class _StepCircle extends StatelessWidget {
  final int number;
  final bool isActive;
  const _StepCircle({required this.number, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        color: isActive ? darkGreen : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: white,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Step Line ─────────────────────────────────────────────────────
class _StepLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        color: darkGreen,
      ),
    );
  }
}

// ── Placeholder if image not found ───────────────────────────────
class _PlaceholderIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified, color: darkGreen, size: 80.sp),
        SizedBox(height: 12.h),
        Text(
          'Payment Done',
          style: TextStyle(color: darkGreen, fontSize: 16.sp),
        ),
      ],
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Home', 'route': '/home'},
      {'icon': Icons.confirmation_number_outlined, 'label': 'Tickets', 'route': '/tickets'},
      {'icon': Icons.qr_code_scanner, 'label': 'Scan QR', 'route': '/scan'},
      {'icon': Icons.person_outline, 'label': 'Profile', 'route': '/profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = index == currentIndex;
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                Navigator.pushNamed(context, items[index]['route'] as String);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  items[index]['icon'] as IconData,
                  color: isSelected ? darkGreen : Colors.grey,
                  size: 24.sp,
                ),
                SizedBox(height: 4.h),
                Text(
                  items[index]['label'] as String,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isSelected ? darkGreen : Colors.grey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  SizedBox(height: 4.h),
                  Container(
                    width: 20.w,
                    height: 2,
                    color: darkGreen,
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}