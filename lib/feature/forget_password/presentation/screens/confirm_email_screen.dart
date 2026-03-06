import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/forget_password_web_services.dart';
import 'otp_screen.dart';

class ConfirmEmailScreen extends StatefulWidget {
  final String fullEmail;
  const ConfirmEmailScreen({super.key, required this.fullEmail});

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  bool _isLoading = false;
  late String maskedEmail;

  @override
  void initState() {
    super.initState();
    maskedEmail = ForgetPasswordWebServices().maskEmail(widget.fullEmail);
  }

  void _sendOtp() async {
    setState(() => _isLoading = true);
    bool ok = true;
    // bool ok = await ForgetPasswordWebServices().requestReset(widget.fullEmail);

    setState(() => _isLoading = false);

    if (ok) {
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(email: widget.fullEmail))
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error sending OTP. Please try again."))
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
            Icon(Icons.mark_email_read_outlined, size: 80.w, color: const Color(0xFF065D45)),
            SizedBox(height: 30.h),
            Text("Is this your email?", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 15.h),
            Text(
              "We found an account linked to:",
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
                  color: const Color(0xFF065D45),
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
                  backgroundColor: const Color(0xFF065D45),
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