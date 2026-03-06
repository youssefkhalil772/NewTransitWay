import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/forget_password_web_services.dart';
import 'success_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String email;
  final String code;
  const ChangePasswordScreen({super.key, required this.email, required this.code});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
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
      bool success = await ForgetPasswordWebServices().confirmReset(widget.email, widget.code, _passController.text);
      setState(() => _isLoading = false);

      if (success) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SuccessScreen()),
                (route) => false
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error resetting password")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(leading: const BackButton(color: Colors.black), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.w),
                Text("Change Password", style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 40.w),
                _buildField(_passController, "New Password", isHidden: _isPasswordHidden, onToggle: () => setState(() => _isPasswordHidden = !_isPasswordHidden)),
                SizedBox(height: 20.w),
                _buildField(_confirmController, "Confirm Password", isConfirm: true, isHidden: _isConfirmPasswordHidden, onToggle: () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden)),
                SizedBox(height: 20.w),
                _buildReq("At least 8 characters", _has8Chars),
                _buildReq("Uppercase & Lowercase letters", _hasUpperLower),
                _buildReq("Numbers & special characters ( !@#%^&* )", _hasNumSpecial),
                SizedBox(height: 60.w),
                SizedBox(
                  width: double.infinity, height: 55.w,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0XFF054F3A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w))),
                    onPressed: _isLoading ? null : _handleReset,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text("Reset Password", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReq(String text, bool met) => Row(children: [Icon(met ? Icons.check_circle : Icons.check_circle_outline, size: 16.sp, color: met ? Colors.green : Colors.grey), SizedBox(width: 8.w), Text(text, style: TextStyle(color: met ? Colors.black : Colors.grey, fontSize: 13.sp))]);

  Widget _buildField(TextEditingController ctrl, String hint, {bool isConfirm = false, required bool isHidden, required VoidCallback onToggle}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isHidden,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0XFF054F3A)),
        suffixIcon: IconButton(icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility), onPressed: onToggle),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.w)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Field required" : (isConfirm && v != _passController.text) ? "Passwords do not match" : null,
    );
  }
}