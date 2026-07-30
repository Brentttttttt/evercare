class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: (map['title'] as String?)?.trim() ?? '',
      body: (map['body'] as String?)?.trim() ?? '',
      kind: (map['kind'] as String?)?.trim() ?? 'general',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  final String id;
  final String title;
  final String body;
  final String kind;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    body: body,
    kind: kind,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}
