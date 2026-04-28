import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/core/resources/color_manager.dart';
import 'package:transite_way/core/routes/routes_manager.dart';
import 'package:transite_way/feature/driver/logic/driver_login_cubit.dart';
import '../forget_password/driver_recovery_screen.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveDriverData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (data['id'] != null) {
      await prefs.setInt('driverId', data['id']);
      await prefs.setInt('userId', data['id']); 
    }
    
    await prefs.setString('driverName', data['name'] ?? "");
    await prefs.setString('driverEmail', data['email'] ?? "");
    await prefs.setString('driverPhone', data['phone'] ?? "");
    await prefs.setString('licenseNumber', data['licenseNumber'] ?? "");
    await prefs.setString('driverStatus', data['status'] ?? "Inactive");
    await prefs.setString('driverPhoto', data['photo'] ?? "");
    
    if (data['busId'] != null) {
      await prefs.setInt('busId', data['busId']);
    }

    await prefs.setString('userRole', 'driver');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverLoginCubit, DriverLoginState>(
      listener: (context, state) {
        if (state is DriverLoginSuccess) {
          _saveDriverData(state.driverData).then((_) {
            RoutesManager.navigateAndRemoveUntil(context, RoutesManager.driverHome);
          });
        } else if (state is DriverLoginError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message.replaceAll('Exception:', '').trim(),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(20.w),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: ColorManager.white,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 25.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 80.h),
                  Text(
                    'Please Sign In',
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B2541),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Enter your account details for a personalised experience.',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: ColorManager.grey,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 50.h),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration('Email', Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your email';
                      if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),

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
                          color: ColorManager.grey4,
                          size: 24.sp,
                        ),
                        onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your password';
                      if (value.length < 8) return 'Password is too short';
                      return null;
                    },
                  ),
                  SizedBox(height: 15.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        // تعديل الربط لفتح شاشة استعادة كلمة مرور السائق
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverRecoveryScreen()),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: ColorManager.lightGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),

                  BlocBuilder<DriverLoginCubit, DriverLoginState>(
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        height: 58.h,
                        child: ElevatedButton(
                          onPressed: state is DriverLoginLoading
                              ? null
                              : () {
                            if (_formKey.currentState!.validate()) {
                              context.read<DriverLoginCubit>().login(
                                _emailController.text,
                                _passwordController.text,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.lightGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            elevation: 0,
                          ),
                          child: state is DriverLoginLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: ColorManager.white, strokeWidth: 2),
                          )
                              : Text(
                            'Sign In',
                            style: TextStyle(
                              color: ColorManager.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: ColorManager.grey4, fontSize: 15.sp),
      prefixIcon: Icon(icon, size: 22.sp, color: ColorManager.grey4),
      contentPadding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      filled: true,
      fillColor: ColorManager.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: BorderSide(color: ColorManager.grey2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: BorderSide(color: ColorManager.grey2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: const BorderSide(color: ColorManager.lightGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
