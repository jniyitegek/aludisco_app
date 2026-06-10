class NotificationModel {
  final int? id;
  final int userId;
  final int senderId;
  final String type; // 'reaction', 'follow', 'opportunity', 'event_reminder', 'reply'
  final int? postId;
  final String message;
  final bool isRead;
  final DateTime timestamp;

  // Joined fields
  final String? senderName;
  final String? senderRole;
  final int? senderAvatarIndex;

  NotificationModel({
    this.id,
    required this.userId,
    required this.senderId,
    required this.type,
    this.postId,
    required this.message,
    required this.isRead,
    required this.timestamp,
    this.senderName,
    this.senderRole,
    this.senderAvatarIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'sender_id': senderId,
      'type': type,
      'post_id': postId,
      'message': message,
      'is_read': isRead ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int? ?? 0,
      senderId: map['sender_id'] as int? ?? 0,
      type: map['type'] as String? ?? 'reaction',
      postId: map['post_id'] as int?,
      message: map['message'] as String? ?? '',
      isRead: (map['is_read'] as int? ?? 0) == 1,
      timestamp: DateTime.parse(map['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      senderName: map['sender_name'] as String?,
      senderRole: map['sender_role'] as String?,
      senderAvatarIndex: map['sender_avatar_index'] as int?,
    );
  }
}
