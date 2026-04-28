import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/core/resources/color_manager.dart';
import 'package:transite_way/feature/driver/data/driver_forget_password_web_services.dart';
import 'driver_success_screen.dart';

class DriverChangePasswordScreen extends StatefulWidget {
  final String email;
  final String code;
  const DriverChangePasswordScreen({super.key, required this.email, required this.code});

  @override
  State<DriverChangePasswordScreen> createState() => _DriverChangePasswordScreenState();
}

class _DriverChangePasswordScreenState extends State<DriverChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  bool _isLoading = false;

  bool _has8Chars = false;
  bool _hasUpperLower = false;
  bool _hasNumSpecial = false;

  @override
  void initState() {
    super.initState();
    _passController.addListener(() {
      String v = _passController.text;
      setState(() {
        _has8Chars = v.length >= 8;
        _hasUpperLower = v.contains(RegExp(r'[A-Z]')) && v.contains(RegExp(r'[a-z]'));
        _hasNumSpecial = v.contains(RegExp(r'[0-9]')) && v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      });
    });
  }

  void _handleReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      bool success = await DriverForgetPasswordWebServices().confirmReset(
        email: widget.email, 
        code: widget.code, 
        newPassword: _passController.text
      );
      setState(() => _isLoading = false);

      if (success) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DriverSuccessScreen()),
                (route) => false
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error resetting password. Please try again."),
            backgroundColor: Colors.redAccent,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.transparent, 
        elevation: 0
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.w),
                Text(
                  "Change Password", 
                  style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E232C))
                ),
                SizedBox(height: 12.h),
                Text(
                  "Create a strong password to protect your driver account.",
                  style: TextStyle(fontSize: 15.sp, color: const Color(0xFF8391A1)),
                ),
                SizedBox(height: 40.w),
                _buildField(_passController, "New Password", isHidden: _isPasswordHidden, onToggle: () => setState(() => _isPasswordHidden = !_isPasswordHidden)),
                SizedBox(height: 20.w),
                _buildField(_confirmController, "Confirm Password", isConfirm: true, isHidden: _isConfirmPasswordHidden, onToggle: () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden)),
                SizedBox(height: 25.w),
                _buildReq("At least 8 characters", _has8Chars),
                _buildReq("Uppercase & Lowercase letters", _hasUpperLower),
                _buildReq("Numbers & special characters ( !@#%^&* )", _hasNumSpecial),
                SizedBox(height: 60.w),
                SizedBox(
                  width: double.infinity, 
                  height: 55.w,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.lightGreen, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w))
                    ),
                    onPressed: _isLoading ? null : _handleReset,
                    child: _isLoading 
                      ? SizedBox(width: 24.w, height: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : Text("Reset Password", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
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

  Widget _buildReq(String text, bool met) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Row(children: [
      Icon(met ? Icons.check_circle : Icons.check_circle_outline, size: 18.sp, color: met ? Colors.green : Colors.grey),
      SizedBox(width: 8.w),
      Text(text, style: TextStyle(color: met ? Colors.black : Colors.grey, fontSize: 14.sp))
    ]),
  );

  Widget _buildField(TextEditingController ctrl, String hint, {bool isConfirm = false, required bool isHidden, required VoidCallback onToggle}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isHidden,
      style: TextStyle(fontSize: 16.sp),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
        prefixIcon: Icon(Icons.lock_outline, color: ColorManager.lightGreen),
        suffixIcon: IconButton(icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility), onPressed: onToggle, color: Colors.grey),
        hintText: hint,
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
      validator: (v) {
        if (v == null || v.isEmpty) return "Field required";
        if (isConfirm && v != _passController.text) return "Passwords do not match";
        if (!isConfirm && (!_has8Chars || !_hasUpperLower || !_hasNumSpecial)) return "Password does not meet requirements";
        return null;
      },
    );
  }
}
