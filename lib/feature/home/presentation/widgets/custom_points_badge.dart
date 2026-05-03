import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/networking/api_constants.dart';
import '../../../../core/networking/supabase_init.dart';

class CustomPointsBadge extends StatefulWidget {
  const CustomPointsBadge({super.key});

  static ValueNotifier<int> balanceNotifier = ValueNotifier<int>(0);

  static Future<void> fetchAndRefreshGlobalBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // طباعة كل الداتا المتسيفة للتأكد
      debugPrint("🔍 All Prefs Keys: ${prefs.getKeys()}");

      final dynamic rawId = prefs.get('userId') ?? prefs.get('id') ?? prefs.get('driverId');
      String? userId;
      if (rawId != null) {
        userId = rawId.toString();
      }

      if (userId == null || userId.isEmpty) {
        debugPrint("⚠️ PointsBadge: No userId found in prefs. Found rawId: $rawId");
        return;
      }

      debugPrint("📡 Fetching balance for userId: $userId");

      final response = await SupabaseConfig.client
          .from(ApiConstants.usersTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      debugPrint("📡 Balance Response: $response");

      if (response != null) {
        int latest = (response['balance'] ?? response['points'] ?? 0).toInt();
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
