import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/core/networking/supabase_init.dart';
import '../home/presentation/widgets/custom_points_badge.dart';
import 'Points.dart';

class ChargePointsScreen extends StatefulWidget {
  final int amount;
  const ChargePointsScreen({super.key, this.amount = 100});

  @override
  State<ChargePointsScreen> createState() => _ChargePointsScreenState();
}

class _ChargePointsScreenState extends State<ChargePointsScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  static const Color _green = Color(0xFF1B4D3E);

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processWalletPayment() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length < 11) {
      setState(() => _errorMessage = 'Please enter a valid wallet phone number (11 digits).');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        throw Exception('User not found. Please log in again.');
      }

      // Call PayMob edge function
      final response = await SupabaseConfig.client.functions.invoke(
        'paymob-pay',
        body: {
          'userId': userId,
          'amount': widget.amount,
          'walletPhone': phone,
        },
      );

      final data = response.data;

      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }

      // Payment initiated successfully
      if (data is Map && data['success'] == true) {
        // Update wallet balance
        final newBalance = data['newBalance'];
        if (newBalance != null) {
          final balance = (newBalance as num).toInt();
          CustomPointsBadge.updateGlobalBalance(balance);
          await prefs.setInt('userPoints', balance);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PointsScreen(pointsAdded: widget.amount),
            ),
          );
        }
      } else {
        // If payment requires redirect (e.g. OTP), handle it
        final redirectUrl = data is Map ? data['redirectUrl']?.toString() : null;
        if (redirectUrl != null) {
          // For now, show a message that OTP verification is needed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment is being processed. Please check your wallet app for OTP confirmation.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else {
          throw Exception('Unexpected payment response. Please try again.');
        }
      }
    } catch (e) {
      debugPrint('PayMob Payment Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyError(e);
          _isProcessing = false;
        });
      }
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Check your connection.';
    }
    if (msg.contains('Insufficient') || msg.contains('balance')) {
      return 'Insufficient wallet balance.';
    }
    if (msg.contains('invalid') || msg.contains('phone')) {
      return 'Invalid wallet phone number.';
    }
    if (msg.contains('not found') || msg.contains('404')) {
      return 'Payment service unavailable. Try again later.';
    }
    // Extract message from Exception
    if (msg.startsWith('Exception: ')) {
      return msg.replaceFirst('Exception: ', '');
    }
    return 'Payment failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Charge My Points",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),

            // Step Indicator
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 80.w),
              child: Row(
                children: [
                  _buildStep(1, isCompleted: true),
                  _buildLine(true),
                  _buildStep(2, isActive: true),
                  _buildLine(false),
                  _buildStep(3),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Payment Method Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF2D7A5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.white, size: 28.sp),
                      SizedBox(width: 12.w),
                      Text(
                        'Electronic Wallet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Pay via Vodafone Cash, Orange Money, Etisalat Cash, or any e-wallet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 28.h),

            // Amount display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FFF4),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFB8E7BE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on_outlined, color: _green, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Charging: ${widget.amount} EGP = ${widget.amount} Points',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      color: _green,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Phone number input
            Text(
              'WALLET PHONE NUMBER',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: _errorMessage != null ? Colors.red.shade300 : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                style: TextStyle(fontSize: 16.sp, color: Colors.black87, letterSpacing: 1.2),
                decoration: InputDecoration(
                  hintText: '01X XXXX XXXX',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15.sp),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 12.w, right: 8.w),
                    child: Icon(Icons.phone_android, color: _green, size: 22.sp),
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 14.sp),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 32.h),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 55.h,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processWalletPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  disabledBackgroundColor: _green.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Processing...',
                            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : Text(
                        'Pay ${widget.amount} EGP',
                        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            SizedBox(height: 20.h),

            // Security note
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  'Secured by PayMob',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12.sp),
                ),
              ],
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int n, {bool isActive = false, bool isCompleted = false}) {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        color: isCompleted || isActive ? _green : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, color: Colors.white, size: 16.sp)
            : Text(
                "$n",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
      ),
    );
  }

  Widget _buildLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2.h,
        color: isActive ? _green : Colors.grey.shade300,
      ),
    );
  }
}