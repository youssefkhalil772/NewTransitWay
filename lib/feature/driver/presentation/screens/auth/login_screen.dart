import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/core/resources/color_manager.dart';
import 'package:transite_way/core/routes/routes_manager.dart';

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
      try {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        setState(() => _isLoading = false);
        RoutesManager.navigateAndRemoveUntil(context, RoutesManager.driverHome);
      } catch (error) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 60.h),

                // ── Title ─────────────────────────────────────────
                Text(
                  'Please Sign In',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.black,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Enter your account details for a personalised experience.',
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorManager.grey1,
                    height: 1.5,
                  ),
                ),

                SizedBox(height: 40.h),

                // ── Email Field ───────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('Email', Icons.email_outlined),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your email' : null,
                ),
                SizedBox(height: 16.h),

                // ── Password Field ────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _buildInputDecoration(
                    'Password (at least 8 characters)',
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: ColorManager.grey,
                        size: 20.sp,
                      ),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (value) =>
                      value!.length < 8 ? 'Password is too short' : null,
                ),

                SizedBox(height: 10.h),

                // ── Forgot Password ───────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => RoutesManager.navigateTo(
                        context, RoutesManager.forgetPassword),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: ColorManager.lightGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // ── Sign In Button ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleDriverLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.lightGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Sign In',
                            style: TextStyle(
                              color: ColorManager.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
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

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: ColorManager.grey, fontSize: 14.sp),
      prefixIcon: Icon(icon, size: 20.sp, color: ColorManager.grey),
      contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: ColorManager.green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
