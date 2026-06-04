import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_manager.dart';
import '../../core/resources/assest_manager.dart';

const Color white = Color(0xFFFFFFFF);
const Color darkGreen = Color(0xFF1B4D3E);

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

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 100.w),
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

          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Center(
                child: Image.asset(
                  ImageAssets.PaymentSuccess,
                  height: 332.h,
                  width: 375.w,
                ),
              ),
            ),
          ),

          SizedBox(height: 28.h),

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
            'Added $pointsAdded Point${pointsAdded > 1 ? 's' : ''} To Your Balance',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
          ),

          SizedBox(height: 28.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  try {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RoutesManager.mainWrapper,
                      (route) => false,
                    );
                  } catch (e) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  }
                },
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
    );
  }
}

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

class _StepLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(height: 2.h, color: darkGreen),
    );
  }
}

class _PlaceholderIllustration extends StatelessWidget {
  const _PlaceholderIllustration();

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
