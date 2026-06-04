import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SosCountdownOverlay extends StatelessWidget {
  final int secondsLeft;
  final VoidCallback onCancel;
  final VoidCallback onSendNow;

  const SosCountdownOverlay({
    super.key,
    required this.secondsLeft,
    required this.onCancel,
    required this.onSendNow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0xFFCC0000).withValues(alpha: 0.96),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 60.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 28.h),

                Text(
                  'Crash Detected!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 10.h),

                Text(
                  'SOS will be sent automatically in',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(height: 28.h),

                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Text(
                      '$secondsLeft',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 52.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 48.h),

                SizedBox(
                  width: double.infinity,
                  height: 60.h,
                  child: ElevatedButton.icon(
                    onPressed: onCancel,
                    icon: Icon(Icons.check_circle_outline, size: 24.sp),
                    label: Text(
                      "I'm OK â€” Cancel",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFCC0000),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                TextButton(
                  onPressed: onSendNow,
                  child: Text(
                    'Send SOS Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SosSentConfirmation extends StatelessWidget {
  final VoidCallback onDismiss;
  final bool isSafeMode;

  const SosSentConfirmation({
    super.key,
    required this.onDismiss,
    this.isSafeMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.97),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110.w,
                  height: 110.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 70.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 28.h),

                Text(
                  isSafeMode ? 'Alarm Cancelled' : 'SOS Sent!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 12.h),

                Text(
                  isSafeMode
                      ? 'Stay safe and drive carefully.'
                      : 'Help is on the way.\nStay calm and stay safe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 16.sp,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 48.h),

                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1B5E20),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
