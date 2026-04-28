import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/core/resources/color_manager.dart';
import 'package:transite_way/feature/driver/data/driver_forget_password_web_services.dart';
import 'driver_otp_screen.dart';

class DriverConfirmEmailScreen extends StatefulWidget {
  final String fullEmail;
  const DriverConfirmEmailScreen({super.key, required this.fullEmail});

  @override
  State<DriverConfirmEmailScreen> createState() => _DriverConfirmEmailScreenState();
}

class _DriverConfirmEmailScreenState extends State<DriverConfirmEmailScreen> {
  bool _isLoading = false;
  late String maskedEmail;

  @override
  void initState() {
    super.initState();
    maskedEmail = DriverForgetPasswordWebServices().maskEmail(widget.fullEmail);
  }

  void _sendOtp() async {
    setState(() => _isLoading = true);

    bool ok = await DriverForgetPasswordWebServices().requestReset(widget.fullEmail);

    setState(() => _isLoading = false);

    if (ok) {
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DriverOtpScreen(email: widget.fullEmail))
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error sending OTP. Please try again."),
            backgroundColor: Colors.redAccent,
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.black)
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40.h),
            Icon(Icons.mark_email_read_outlined, size: 80.w, color: ColorManager.lightGreen),
            SizedBox(height: 30.h),
            Text("Is this your email?", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 15.h),
            Text(
              "We found a driver account linked to:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 25.h),

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade200)
              ),
              child: Text(
                maskedEmail,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorManager.lightGreen,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.lightGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed: _isLoading ? null : _sendOtp,
                child: _isLoading
                    ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : Text("Yes, Send Code", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
