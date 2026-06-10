class MessageModel {
  final int? id;
  final int senderId;
  final int? receiverId; // for 1:1 DMs
  final int? eventId;    // for event group chats
  final int? spaceId;    // for space discussion threads
  final String content;
  final DateTime timestamp;

  // Joined fields
  final String? senderName;
  final String? senderRole;
  final int? senderAvatarIndex;

  MessageModel({
    this.id,
    required this.senderId,
    this.receiverId,
    this.eventId,
    this.spaceId,
    required this.content,
    required this.timestamp,
    this.senderName,
    this.senderRole,
    this.senderAvatarIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'event_id': eventId,
      'space_id': spaceId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as int?,
      senderId: map['sender_id'] as int? ?? 0,
      receiverId: map['receiver_id'] as int?,
      eventId: map['event_id'] as int?,
      spaceId: map['space_id'] as int?,
      content: map['content'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      senderName: map['sender_name'] as String?,
      senderRole: map['sender_role'] as String?,
      senderAvatarIndex: map['sender_avatar_index'] as int?,
    );
  }
}
