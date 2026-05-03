class NotificationResponse {
  final String userId;
  final int unreadCount;
  final List<NotificationModel> notifications;

  NotificationResponse({
    required this.userId,
    required this.unreadCount,
    required this.notifications,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      userId: (json['user_id'] ?? json['userId'])?.toString() ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      notifications: (json['notifications'] as List? ?? [])
          .map((i) => NotificationModel.fromJson(i))
          .toList(),
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    String dateStr = json['created_at'] ?? json['createdAt'] ?? '';
    DateTime parsedDate;

    if (dateStr.isNotEmpty) {
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
        dateStr += 'Z';
      }
      parsedDate = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      createdAt: parsedDate,
    );
  }
}
