import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'data/notification_model.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailsScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    Color themeColor = const Color(0xFF064E3B);
    IconData icon = Icons.notifications;

    final title = notification.title.toLowerCase();
    if (title.contains('warning') || title.contains('تحذير') || title.contains('suspended')) {
      themeColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
    } else if (title.contains('restored') || title.contains('تم') || title.contains('success')) {
      themeColor = Colors.green;
      icon = Icons.check_circle_outline;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notification Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: themeColor, size: 50.sp),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              notification.title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              DateFormat('EEEE, MMM d, yyyy - hh:mm a').format(notification.createdAt),
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 24.h),
            const Divider(),
            SizedBox(height: 24.h),
            Text(
              notification.body,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
