import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../login/login.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            const Spacer(flex: 2),

            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/icons/circle_check.png',
                    width: 160.w,
                    height: 160.w,
                    fit: BoxFit.contain,
                  ),
                  Image.asset(
                    'assets/icons/tabler_check.png',
                    width: 60.w,
                    height: 60.w,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            SizedBox(height: 40.h),

            Text(
              "Password has been\nchanged",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E232C),
                height: 1.2,
              ),
            ),

            SizedBox(height: 16.h),

            Text(
              "Don't worry, we'll let you know if there's a\nproblem with your account",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF8391A1),
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),

            const Spacer(flex: 3),

            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0XFF054F3A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()), // استبدل LoginScreen باسم كلاس اللوجين عندك
                          (route) => false,);
                  },
                child: Text(
                  "Back to Login",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}