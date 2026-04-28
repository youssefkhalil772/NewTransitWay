class NotificationResponse {
  final int userId;
  final int unreadCount;
  final List<NotificationModel> notifications;

  NotificationResponse({
    required this.userId,
    required this.unreadCount,
    required this.notifications,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      userId: json['userId'] ?? 0,
      unreadCount: json['unreadCount'] ?? 0,
      notifications: (json['notifications'] as List? ?? [])
          .map((i) => NotificationModel.fromJson(i))
          .toList(),
    );
  }
}

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    String dateStr = json['createdAt'] ?? '';
    DateTime parsedDate;

    if (dateStr.isNotEmpty) {
      // لو السيرفر مش باعت حرف 'Z' في الآخر، الـ Dart بيفهم إن الوقت ده Local
      // فإحنا بنجبره يفهم إنه UTC الأول عشان لما نحوله لـ Local يزود الـ 3 ساعات بتوع مصر
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
        dateStr += 'Z';
      }
      parsedDate = DateTime.parse(dateStr).toLocal();
    } else {
      parsedDate = DateTime.now();
    }

    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: parsedDate,
    );
  }
}
