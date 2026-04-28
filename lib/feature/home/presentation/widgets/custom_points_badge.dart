import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/networking/api_constants.dart';

class CustomPointsBadge extends StatefulWidget {
  const CustomPointsBadge({super.key});

  static ValueNotifier<int> balanceNotifier = ValueNotifier<int>(0);

  static Future<void> fetchAndRefreshGlobalBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // طباعة كل الداتا المتسيفة للتأكد
      debugPrint("🔍 All Prefs Keys: ${prefs.getKeys()}");

      // محاولة جلب الـ ID بأكثر من مسمى
      final dynamic rawId = prefs.get('userId') ?? prefs.get('id') ?? prefs.get('driverId');
      int? userId;
      if (rawId is int) userId = rawId;
      else if (rawId is String) userId = int.tryParse(rawId);

      if (userId == null || userId == 0) {
        debugPrint("⚠️ PointsBadge: No userId found in prefs. Found rawId: $rawId");
        return;
      }

      final url = "${ApiConstants.baseUrl}${ApiConstants.userBalance(userId)}";
      debugPrint("📡 Fetching balance from: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 5));

      debugPrint("📡 Balance Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        int latest = 0;
        if (data is Map) {
          latest = (data['balancePoints'] ?? 0).toInt();
        } else if (data is num) {
          latest = data.toInt();
        }

        balanceNotifier.value = latest;
        await prefs.setInt('userPoints', latest);
        debugPrint("✅ Balance Linked: $latest");
      }
    } catch (e) {
      debugPrint("🛑 Points Link Error: $e");
    }
  }

  static void updateGlobalBalance(int newBalance) {
    balanceNotifier.value = newBalance;
  }

  @override
  State<CustomPointsBadge> createState() => _CustomPointsBadgeState();
}

class _CustomPointsBadgeState extends State<CustomPointsBadge> {
  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    int saved = prefs.getInt('userPoints') ?? 0;
    if (CustomPointsBadge.balanceNotifier.value == 0) {
      CustomPointsBadge.updateGlobalBalance(saved);
    }
    CustomPointsBadge.fetchAndRefreshGlobalBalance();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CustomPointsBadge.balanceNotifier,
      builder: (context, currentBalance, _) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: const Color(0xFFCDDFDA),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars, color: Colors.amber, size: 20.sp),
              SizedBox(width: 6.w),
              Text(
                currentBalance.toString(),
                style: TextStyle(
                  color: const Color(0xFF1B4D3E),
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
