import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/networking/api_constants.dart';
import '../../../core/routes/routes_manager.dart';
import 'notification_model.dart';

// تعريف الـ GlobalKey للوصول للـ Context من أي مكان
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  Timer? _pollingTimer;
  int? _lastNotificationId;
  
  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  void startMonitoring() async {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkForNewNotifications();
    });
    _checkForNewNotifications();
  }

  void stopMonitoring() {
    _pollingTimer?.cancel();
  }

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawId = prefs.get('userId') ?? prefs.get('id');
    if (rawId is int) return rawId;
    if (rawId is String) return int.tryParse(rawId);
    return null;
  }

  Future<NotificationResponse?> fetchNotifications() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return null;

      final url = "${ApiConstants.baseUrl}${ApiConstants.userNotifications(userId)}";
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = NotificationResponse.fromJson(jsonDecode(response.body));
        _unreadCountController.add(data.unreadCount);
        return data;
      }
    } catch (e) {
      debugPrint("🛑 Fetch Notifications Error: $e");
    }
    return null;
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return false;

      final url = "${ApiConstants.baseUrl}${ApiConstants.markNotificationRead(userId, notificationId)}";
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        fetchNotifications(); 
        return true;
      }
    } catch (e) {
      debugPrint("🛑 Mark Read Error: $e");
    }
    return false;
  }

  Future<bool> markAllAsRead() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return false;

      final url = "${ApiConstants.baseUrl}${ApiConstants.markAllNotificationsRead(userId)}";
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        _unreadCountController.add(0);
        return true;
      }
    } catch (e) {
      debugPrint("🛑 Mark All Read Error: $e");
    }
    return false;
  }

  Future<void> _checkForNewNotifications() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return;

      final url = "${ApiConstants.baseUrl}${ApiConstants.userNotifications(userId)}";
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final int unreadCount = data['unreadCount'] ?? 0;
        _unreadCountController.add(unreadCount);

        final List<dynamic> notifications = data['notifications'] ?? [];
        if (notifications.isNotEmpty) {
          final latest = notifications.first;
          final int latestId = latest['id'];

          if (latestId != _lastNotificationId && latest['isRead'] == false) {
            _lastNotificationId = latestId;
            _showInAppBanner(latest);
          }
        }
      }
    } catch (e) {
      debugPrint("🛑 InApp Notification Error: $e");
    }
  }

  void _showInAppBanner(Map<String, dynamic> data) {
    Color bgColor = const Color(0xFF1B4D3E);
    IconData iconData = Icons.notifications_active;

    String title = data['title']?.toString() ?? "";
    String body = data['body']?.toString() ?? "";
    
    bool isBan = title.toLowerCase().contains('suspended') || 
                 title.contains('تعليق') || 
                 body.toLowerCase().contains('suspended') ||
                 body.contains('تعليق') ||
                 body.contains('تم حظر');

    if (isBan) {
      bgColor = Colors.red;
      iconData = Icons.block;
      _showForcedBanDialog(title, body);
    } else if (title.toLowerCase().contains('warning') || title.contains('تحذير')) {
      bgColor = Colors.orange;
      iconData = Icons.warning_amber_rounded;
    } else if (title.toLowerCase().contains('restored') || title.contains('تم')) {
      bgColor = Colors.green;
      iconData = Icons.check_circle_outline;
    }

    showSimpleNotification(
      Text(
        title.isEmpty ? "تنبيه جديد" : title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        body,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      background: bgColor,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
        child: Icon(iconData, color: Colors.white, size: 20),
      ),
      duration: isBan ? const Duration(seconds: 10) : const Duration(seconds: 5),
    );
  }

  void _showForcedBanDialog(String title, String body) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFFCEBEB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.block_rounded, color: Color(0xFFE24B4A), size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                title.isNotEmpty ? title : 'Account Suspended',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (context.mounted) {
                      RoutesManager.navigateAndRemoveUntil(context, RoutesManager.role);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE24B4A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
