import 'dart:async';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/networking/api_constants.dart';
import '../../../core/networking/supabase_init.dart';
import '../../../core/routes/routes_manager.dart';
import 'notification_model.dart';

// Global NavigatorKey for accessing context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _userSub;
  String? _lastNotificationId;
  final Set<String> _seenNotificationIds = {};
  bool _isInitialized = false;
  
  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  Future<void> startMonitoring() async {
    stopMonitoring(); // Ensure any existing listeners are cleared

    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) return;

    // 1. Listen for Notifications via Stream
    _notificationsSub = SupabaseConfig.client
        .from(ApiConstants.notificationsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isEmpty) {
            _unreadCountController.add(0);
            _isInitialized = true;
            return;
          }
          
          // Count unread
          final unreadCount = data.where((n) => (n['is_read'] ?? n['isRead'] ?? false) == false).length;
          _unreadCountController.add(unreadCount);

          // Find newly inserted notifications by checking seen IDs
          for (var notif in data) {
            final id = notif['id']?.toString();
            final isRead = notif['is_read'] ?? notif['isRead'] ?? false;
            
            if (id != null && !_seenNotificationIds.contains(id)) {
              _seenNotificationIds.add(id);
              
              // Only show popup for unread notifications AFTER initial load
              if (_isInitialized && isRead == false) {
                debugPrint("📡 Stream New Notification Payload: $notif");
                _showInAppBanner(notif);
              }
            }
          }
          
          _isInitialized = true;
        }, onError: (err) {
          debugPrint("📡 Stream Notification Error: $err");
        });

    // 2. Listen for User Profile Updates (specifically Ban Status)
    _userSub = SupabaseConfig.client
        .from(ApiConstants.usersTable)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final userData = data.first;
            
            // 1. Check for ban status
            if (userData['is_banned'] == true) {
              final reason = userData['ban_reason']?.toString() ?? 'Your account has been suspended.';
              _showForcedBanDialog('Account Suspended', reason);
            }
            
            // 2. Check for warning field in users table (instant alert)
            final userWarning = userData['warning'] ?? userData['worning'];
            if (userWarning != null && userWarning.toString().isNotEmpty) {
              _showInAppBanner({
                'title': 'Account Warning',
                'body': userWarning.toString(),
                'is_read': false,
              });
            }
          }
        }, onError: (err) {
          debugPrint("📡 Stream User Error: $err");
        });

    // Initial check
    checkBanStatus();
  }

  void stopMonitoring() {
    _notificationsSub?.cancel();
    _notificationsSub = null;
    
    _userSub?.cancel();
    _userSub = null;
  }

  /// Returns the current user's UUID from SharedPreferences.
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<NotificationResponse?> fetchNotifications() async {
    try {
      final userId = await _getUserId();
      if (userId == null || userId.isEmpty) return null;

      // 1. Fetch from notifications table
      final notifications = await SupabaseConfig.client
          .from(ApiConstants.notificationsTable)
          .select()
          .eq('user_id', userId);

      final List<NotificationModel> notifList = (notifications as List)
          .map((i) => NotificationModel.fromJson(i))
          .toList();

      // 2. Also check for a global warning in the users table
      final userData = await SupabaseConfig.client
          .from(ApiConstants.usersTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (userData != null) {
        final userWarning = userData['warning'] ?? userData['worning'];
        if (userWarning != null && userWarning.toString().isNotEmpty) {
          // Add it as a virtual notification at the top
          notifList.insert(0, NotificationModel(
            id: '-99', 
            title: "Account Warning",
            body: userWarning.toString(),
            type: 'warning',
            isRead: false,
            createdAt: DateTime.tryParse(userData['created_at']?.toString() ?? '') ?? DateTime.now(),
          ));
        }
      }

      // Sort locally to avoid crashes if created_at column is missing in DB
      notifList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final int unreadCount = notifList.where((n) => !n.isRead).length;

      final data = NotificationResponse(
        userId: userId,
        unreadCount: unreadCount,
        notifications: notifList,
      );

      _unreadCountController.add(data.unreadCount);
      return data;
    } catch (e) {
      debugPrint("🛑 Fetch Notifications Error: $e");
    }
    return null;
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return false;

      await SupabaseConfig.client
          .from(ApiConstants.notificationsTable)
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);

      fetchNotifications(); 
      return true;
    } catch (e) {
      debugPrint("🛑 Mark Read Error: $e");
    }
    return false;
  }

  Future<bool> markAllAsRead() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return false;

      await SupabaseConfig.client
          .from(ApiConstants.notificationsTable)
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      _unreadCountController.add(0);
      return true;
    } catch (e) {
      debugPrint("🛑 Mark All Read Error: $e");
    }
    return false;
  }

  /// Checks if the current user is banned. Returns true if banned.
  Future<bool> checkBanStatus() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return false;

      final userData = await SupabaseConfig.client
          .from(ApiConstants.usersTable)
          .select() // Select all columns to catch warning/worning
          .eq('id', userId)
          .maybeSingle();

      if (userData != null) {
        // 1. Check for ban
        if (userData['is_banned'] == true) {
          final reason = userData['ban_reason']?.toString() ?? 'Your account has been suspended.';
          _showForcedBanDialog('Account Suspended', reason);
          return true;
        }
        
        // 2. Check for warning/worning field directly in user table
        final userWarning = userData['warning'] ?? userData['worning'];
        if (userWarning != null && userWarning.toString().isNotEmpty) {
           _showInAppBanner({
             'title': 'System Warning',
             'body': userWarning.toString(),
             'is_read': false,
           });
        }
      }
    } catch (e) {
      debugPrint("⚠️ Ban check error: $e");
    }
    return false;
  }

  void _showInAppBanner(Map<String, dynamic> data) {
    Color bgColor = const Color(0xFF1B4D3E);
    IconData iconData = Icons.notifications_active;

    String title = (data['title'] ?? "").toString();
    String body = (data['body'] ?? "").toString();
    bool isRead = data['is_read'] ?? data['isRead'] ?? false;
    
    if (isRead) return; 

    bool isBan = title.toLowerCase().contains('suspended') || 
                 body.toLowerCase().contains('suspended') ||
                 body.toLowerCase().contains('banned');

    if (isBan) {
      bgColor = Colors.red;
      iconData = Icons.block;
      _showForcedBanDialog(title, body);
      return; 
    } else if (title.toLowerCase().contains('warning')) {
      bgColor = Colors.orange;
      iconData = Icons.warning_amber_rounded;
    } else if (title.toLowerCase().contains('restored') || title.toLowerCase().contains('success')) {
      bgColor = Colors.green;
      iconData = Icons.check_circle_outline;
    }

    showSimpleNotification(
      Text(
        title.isEmpty ? "New Alert" : title,
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
      duration: const Duration(seconds: 5),
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
                    // Sign out and stop monitoring
                    stopMonitoring();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    await SupabaseConfig.client.auth.signOut();
                    
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
