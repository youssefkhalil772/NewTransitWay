import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'home/driver_home_screen.dart';
// استيراد الخدمات والصفحة الجديدة (تأكد من المسارات في مشروعك)
// import 'driver_home_screen.dart';
// import 'driver_auth_services.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleDriverLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // محاكاة الاتصال بالـ API (سيتم ربطه لاحقاً)
      try {
        // await DriverAuthServices().login(_emailController.text, _passwordController.text);
        await Future.delayed(const Duration(seconds: 2)); // وهمي للتحميل

        if (!mounted) return;
        setState(() => _isLoading = false);

        // الانتقال لصفحة السائق
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
              (route) => false,
        );
      } catch (error) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 100.h),
                Text(
                  'Driver Sign In',
                  style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1B1B1B)),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Welcome back, Captain! Please enter your \ncredentials to start your shift.',
                  style: TextStyle(fontSize: 15.sp, color: Colors.grey, height: 1.5),
                ),
                SizedBox(height: 50.h),

                // حقل الإيميل
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('Driver Email', Icons.badge_outlined),
                  validator: (value) => value!.isEmpty ? 'Please enter email' : null,
                ),
                SizedBox(height: 20.h),

                // حقل الباسورد
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _buildInputDecoration('Password', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (value) => value!.length < 6 ? 'Password is too short' : null,
                ),

                SizedBox(height: 40.h),

                // زر الدخول
                SizedBox(
                  width: double.infinity,
                  height: 55.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleDriverLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF064E3B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Login as Driver', style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 22.sp),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
    );
  }
}