import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/core/routes/routes_manager.dart';

class DriverSuccessScreen extends StatelessWidget {
  const DriverSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 25.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF39C449), size: 60),
            ),
            SizedBox(height: 32.h),
            Text(
              "Password Changed!",
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1B2541)),
            ),
            SizedBox(height: 12.h),
            Text(
              "Your driver account password has been successfully updated. You can now log in with your new password.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, color: Colors.grey, height: 1.5),
            ),
            SizedBox(height: 50.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39C449),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                  elevation: 0,
                ),
                onPressed: () {
                  // العودة لشاشة دخول السائق
                  RoutesManager.navigateAndRemoveUntil(context, RoutesManager.loginDriver);
                },
                child: Text("Back to Login", style: TextStyle(color: Colors.white, fontSize: 17.sp, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
