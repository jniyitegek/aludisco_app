class CommentModel {
  final int? id;
  final int postId;
  final int authorId;
  final String content;
  final int? parentId; // Null for top-level, int for nested replies
  final DateTime timestamp;

  // Joined/Populated fields
  final String? authorName;
  final String? authorRole;
  final int? authorAvatarIndex;
  final bool? authorIsVerified;
  final List<CommentModel> replies; // Loaded recursively/programmatically

  CommentModel({
    this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    this.parentId,
    required this.timestamp,
    this.authorName,
    this.authorRole,
    this.authorAvatarIndex,
    this.authorIsVerified,
    this.replies = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'post_id': postId,
      'author_id': authorId,
      'content': content,
      'parent_id': parentId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, {List<CommentModel> repliesList = const []}) {
    return CommentModel(
      id: map['id'] as int?,
      postId: map['post_id'] as int? ?? 0,
      authorId: map['author_id'] as int? ?? 0,
      content: map['content'] as String? ?? '',
      parentId: map['parent_id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      authorName: map['author_name'] as String?,
      authorRole: map['author_role'] as String?,
      authorAvatarIndex: map['author_avatar_index'] as int?,
      authorIsVerified: map['author_is_verified'] != null ? (map['author_is_verified'] as int) == 1 : null,
      replies: repliesList,
    );
  }

  CommentModel copyWith({
    int? id,
    int? postId,
    int? authorId,
    String? content,
    int? parentId,
    DateTime? timestamp,
    String? authorName,
    String? authorRole,
    int? authorAvatarIndex,
    bool? authorIsVerified,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      timestamp: timestamp ?? this.timestamp,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      authorAvatarIndex: authorAvatarIndex ?? this.authorAvatarIndex,
      authorIsVerified: authorIsVerified ?? this.authorIsVerified,
      replies: replies ?? this.replies,
    );
  }
}
