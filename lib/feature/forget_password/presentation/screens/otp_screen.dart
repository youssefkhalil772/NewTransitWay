import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/forget_password_web_services.dart';
import 'change_password_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  bool _isLoading = false;
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (index) => TextEditingController());
    _focusNodes = List.generate(6, (index) => FocusNode());
    _startTimer();
  }

  void _startTimer() {
    setState(() { _secondsRemaining = 60; _canResend = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() { _timer?.cancel(); _canResend = true; });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _showCustomError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  void _handleVerify() async {
    String fullCode = _controllers.map((e) => e.text).join();
    if (fullCode.length == 6) {
      setState(() => _isLoading = true);
      bool isValid = await ForgetPasswordWebServices().verifyOtp(email: widget.email, otp: fullCode);
      setState(() => _isLoading = false);
      if (isValid) {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen(email: widget.email, code: fullCode)));
      } else {
        _showCustomError("The code is incorrect. Please try again.");
      }
    } else {
      _showCustomError("Please enter the 6-digit code");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var n in _focusNodes) n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(leading: const BackButton(color: Colors.black), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.w),
            Text("Enter the code", style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 10.w),
            Text("An authentification code has been\nsent to your email", style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
            SizedBox(height: 40.w),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => _otpBox(index)),
            ),
            SizedBox(height: 30.w),
            Center(
              child: Column(
                children: [
                  Text(_secondsRemaining > 0 ? "Resend in 00:${_secondsRemaining.toString().padLeft(2, '0')}" : "Didn't receive code?", style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: _canResend ? () async {
                      _startTimer();
                      await ForgetPasswordWebServices().requestReset(widget.email);
                    } : null,
                    child: Text("Resend Code", style: TextStyle(color: _canResend ? const Color(0XFF054F3A) : Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 55.w,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0XFF054F3A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w))),
                onPressed: _isLoading ? null : _handleVerify,
                child: _isLoading ? SizedBox(width: 25.w, height: 25.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text("Verify", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 30.w),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 45.w, height: 55.w,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_controllers[index].text.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
          }
        },
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0XFF054F3A)),
          keyboardType: TextInputType.number,
          inputFormatters: [LengthLimitingTextInputFormatter(1), FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) { if (v.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus(); },
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.w), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.w), borderSide: const BorderSide(color: Color(0XFF054F3A), width: 1.5)),
          ),
        ),
      ),
    );
  }
}