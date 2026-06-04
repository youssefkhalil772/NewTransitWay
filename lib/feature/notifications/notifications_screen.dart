import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/networking/api_constants.dart';
import '../../core/networking/supabase_init.dart';
import '../../core/routes/routes_manager.dart';
import 'data/notification_model.dart';
import 'data/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final InAppNotificationService _notificationService =
      InAppNotificationService();

  StreamSubscription<List<Map<String, dynamic>>>? _notifStream;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initRealtime();
  }

  @override
  void dispose() {
    _notifStream?.cancel();
    super.dispose();
  }

  Future<void> _initRealtime() async {
    _userId = SupabaseConfig.client.auth.currentUser?.id;
    if (_userId == null || _userId!.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');
    }

    if (_userId == null || _userId!.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _notifStream?.cancel();
    _notifStream = SupabaseConfig.client
        .from(ApiConstants.notificationsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId!)
        .listen(
          (List<Map<String, dynamic>> data) {
            if (!mounted) return;

            final List<NotificationModel> notifList = data
                .map((i) => NotificationModel.fromJson(i))
                .toList();

            _appendUserWarningIfNeeded(notifList);
          },
          onError: (e) {
            debugPrint('ðŸ“¡ NotificationsScreen stream error: $e');
            if (mounted) setState(() => _isLoading = false);
          },
        );
  }

  Future<void> _appendUserWarningIfNeeded(
    List<NotificationModel> notifList,
  ) async {
    try {
      if (_userId != null) {
        final userData = await SupabaseConfig.client
            .from(ApiConstants.usersTable)
            .select('warning, worning, created_at')
            .eq('id', _userId!)
            .maybeSingle();

        if (userData != null) {
          final userWarning = userData['warning'] ?? userData['worning'];
          if (userWarning != null && userWarning.toString().isNotEmpty) {
            notifList.insert(
              0,
              NotificationModel(
                id: '-99',
                title: 'Account Warning',
                body: userWarning.toString(),
                type: 'warning',
                isRead: false,
                createdAt:
                    DateTime.tryParse(
                      userData['created_at']?.toString() ?? '',
                    ) ??
                    DateTime.now(),
              ),
            );
          }
        }
      }
    } catch (_) {}

    notifList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final unread = notifList.where((n) => !n.isRead).length;
    _notificationService.updateUnreadCountPublic(unread);

    if (mounted) {
      setState(() {
        _notifications = notifList;
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _initRealtime();
  }

  Future<void> _markAllRead() async {
    final success = await _notificationService.markAllAsRead();
    if (success && mounted) {}
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    RoutesManager.navigateTo(
      context,
      RoutesManager.notificationDetails,
      arguments: notification,
    );

    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Color(0xFF39C449)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF064E3B)),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.all(20.w),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => SizedBox(height: 15.h),
                      itemBuilder: (context, index) =>
                          _buildNotificationCard(_notifications[index]),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 80.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            const Text(
              'No notifications yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8.h),
            const Text(
              'Pull down to refresh',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    Color color = const Color(0xFF064E3B);
    IconData icon = Icons.notifications_none;
    Color bgColor = Colors.white;

    final title = notification.title.toLowerCase();
    final type = notification.type.toLowerCase();

    if (type == 'ban' ||
        title.contains('suspended') ||
        title.contains('banned')) {
      color = Colors.red;
      icon = Icons.block;
      bgColor = const Color(0xFFFCEBEB);
    } else if (type == 'warning' || title.contains('warning')) {
      color = Colors.orange;
      icon = Icons.warning_amber_rounded;
      bgColor = const Color(0xFFFFF9F0);
    } else if (type == 'success' ||
        title.contains('restored') ||
        title.contains('success')) {
      color = Colors.green;
      icon = Icons.check_circle_outline;
      bgColor = const Color(0xFFF0FFF4);
    } else if (type == 'info' ||
        title.contains('info') ||
        title.contains('update')) {
      color = Colors.blue;
      icon = Icons.info_outline;
      bgColor = const Color(0xFFF0F7FF);
    }

    String timeAgo = DateFormat('jm').format(notification.createdAt);
    if (DateTime.now().difference(notification.createdAt).inDays > 0) {
      timeAgo = DateFormat('MMMd').format(notification.createdAt);
    }

    return GestureDetector(
      onTap: () => _onNotificationTap(notification),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            if (!notification.isRead)
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: EdgeInsets.only(left: 8.w, top: 4.h),
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  color: Color(0xFF39C449),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
