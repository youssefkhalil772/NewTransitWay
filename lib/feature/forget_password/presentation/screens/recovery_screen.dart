import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/forget_password_web_services.dart';
import 'confirm_email_screen.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _showSnackBar(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.redAccent : const Color(0XFF054F3A),
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
      // الحل: SingleChildScrollView بيخلي الصفحة تترفع مع الكيبورد وسلسة في الحركة
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
                  "Enter your phone number to recover your password",
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: const Color(0xFF8391A1),
                  ),
                ),
                SizedBox(height: 40.h),

                // حقل إدخال رقم الموبايل
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(fontSize: 16.sp),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
                    prefixIcon: Icon(Icons.phone_android_outlined, color: const Color(0XFF054F3A), size: 22.sp),
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
                      borderSide: const BorderSide(color: Color(0XFF054F3A), width: 1.5),
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

                // المسافة اللي كانت مخلية الزرار "ثابت" في النص تم ضبطها هنا
                SizedBox(height: 80.h),

                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0XFF054F3A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: _isLoading ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _isLoading = true);

                        // --- نظام الـ Skip مؤقتاً للتجربة ---
                        await Future.delayed(const Duration(seconds: 1));
                        String? fakeEmail = "youssefmahmoud772@gmail.com";

                        setState(() => _isLoading = false);

                        if (fakeEmail != null && mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConfirmEmailScreen(fullEmail: fakeEmail),
                            ),
                          );
                        } else if (mounted) {
                          _showSnackBar("No account found with this phone number", true);
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
                SizedBox(height: 40.h), // مسافة أمان في نهاية الصفحة
              ],
            ),
          ),
        ),
      ),
    );
  }
}