class AppNotificationItem {
  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.data,
    required this.read,
  });

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final Map<String, dynamic> data;
  final bool read;

  AppNotificationItem copyWith({bool? read}) {
    return AppNotificationItem(
      id: id,
      title: title,
      body: body,
      receivedAt: receivedAt,
      data: data,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'data': data,
        'read': read,
      };

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      receivedAt: DateTime.tryParse((json['receivedAt'] ?? '').toString()) ?? DateTime.now(),
      data: Map<String, dynamic>.from((json['data'] as Map?) ?? const {}),
      read: (json['read'] as bool?) ?? false,
    );
  }
}
