import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../core/routes/routes_manager.dart';
import 'data/notification_model.dart';
import 'data/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final InAppNotificationService _notificationService = InAppNotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final response = await _notificationService.fetchNotifications();
    if (mounted) {
      setState(() {
        _notifications = response?.notifications ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    final success = await _notificationService.markAllAsRead();
    if (success && mounted) {
      _loadNotifications();
    }
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    // الانتقال لصفحة التفاصيل
    RoutesManager.navigateTo(
      context,
      RoutesManager.notificationDetails,
      arguments: notification,
    );

    // لو الإشعار مش مقروء، نخليه مقروء في الخلفية
    if (!notification.isRead) {
      final success = await _notificationService.markAsRead(notification.id);
      if (success && mounted) {
        // نحدث القائمة محلياً عشان لما يرجع يلاقيها مقروءة
        _loadNotifications();
      }
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
          "Notifications",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text("Mark all read", style: TextStyle(color: Color(0xFF39C449))),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF064E3B)))
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.all(20.w),
                      itemCount: _notifications.length,
                      separatorBuilder: (context, index) => SizedBox(height: 15.h),
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(_notifications[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 80.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          const Text("No notifications yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    Color color = const Color(0xFF064E3B);
    IconData icon = Icons.notifications_none;
    Color bgColor = Colors.white;

    final title = notification.title.toLowerCase();
    if (title.contains('warning') || title.contains('تحذير') || title.contains('suspended')) {
      color = Colors.orange;
      icon = Icons.warning_amber_rounded;
      bgColor = const Color(0xFFFFF9F0);
    } else if (title.contains('restored') || title.contains('تم') || title.contains('success')) {
      color = Colors.green;
      icon = Icons.check_circle_outline;
      bgColor = const Color(0xFFF0FFF4);
    } else if (title.contains('info') || title.contains('تحديث')) {
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
      child: Container(
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
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(timeAgo, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
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
                decoration: const BoxDecoration(color: Color(0xFF39C449), shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
