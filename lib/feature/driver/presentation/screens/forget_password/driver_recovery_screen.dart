import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/core/resources/color_manager.dart';
import 'package:transite_way/feature/driver/data/driver_forget_password_web_services.dart';
import 'driver_confirm_email_screen.dart';

class DriverRecoveryScreen extends StatefulWidget {
  const DriverRecoveryScreen({super.key});

  @override
  State<DriverRecoveryScreen> createState() => _DriverRecoveryScreenState();
}

class _DriverRecoveryScreenState extends State<DriverRecoveryScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _showSnackBar(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.redAccent : ColorManager.lightGreen,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30.h),
                Text(
                  "Password Recovery",
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E232C),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  "Enter your phone number to recover your driver account password",
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: const Color(0xFF8391A1),
                  ),
                ),
                SizedBox(height: 40.h),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(fontSize: 16.sp),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
                    prefixIcon: Icon(Icons.phone_android_outlined, color: ColorManager.lightGreen, size: 22.sp),
                    hintText: "Phone Number",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14.sp),
                    filled: true,
                    fillColor: const Color(0xFFF7F8F9),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFFE8ECF4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: ColorManager.lightGreen, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty || v.length < 11)
                      ? "Please enter a valid phone number"
                      : null,
                ),

                SizedBox(height: 80.h),

                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.lightGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: _isLoading ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _isLoading = true);

                        final webServices = DriverForgetPasswordWebServices();
                        String? realEmail = await webServices.getEmailByPhone(
                            _phoneController.text.trim()
                        );

                        setState(() => _isLoading = false);

                        if (realEmail != null && mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DriverConfirmEmailScreen(fullEmail: realEmail),
                            ),
                          );
                        } else if (mounted) {
                          _showSnackBar("No driver account found with this phone number", true);
                        }
                      }
                    },
                    child: _isLoading
                        ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : Text(
                      "Find Account",
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
        ),
      ),
    );
  }
}
