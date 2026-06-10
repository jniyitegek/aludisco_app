class PostModel {
  final int? id;
  final int authorId;
  final String title;
  final String description;
  final String type; // 'achievement', 'opportunity'
  final String category; // 'Career Win', 'Project Launch', etc., or 'Event', 'Hackathon'
  final String? imagePath;
  final DateTime timestamp;
  final int? spaceId;
  final bool pinned;

  // Opportunity specific fields
  final DateTime? eventDate;
  final String? eventLocation;
  final String? registrationLink;
  final bool inAppRsvp;
  final List<String> targetAudience;

  // Joined fields (for feed queries)
  final String? authorName;
  final String? authorRole;
  final int? authorAvatarIndex;
  final bool? authorIsVerified;
  final String? authorSubtitle; // e.g. "Class of 2024" or "Organizer"
  final Map<String, int> reactionCounts; // {'respect': X, 'impressive': Y, 'inspired': Z}
  final String? userReaction; // the current user's reaction type if any
  final int commentCount;
  final bool isSaved; // whether the current user saved/bookmarked it
  final int attendeeCount;
  final String? userRsvpStatus; // 'upcoming', 'attended', 'cancelled', or null

  PostModel({
    this.id,
    required this.authorId,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    this.imagePath,
    required this.timestamp,
    this.spaceId,
    required this.pinned,
    this.eventDate,
    this.eventLocation,
    this.registrationLink,
    required this.inAppRsvp,
    required this.targetAudience,
    this.authorName,
    this.authorRole,
    this.authorAvatarIndex,
    this.authorIsVerified,
    this.authorSubtitle,
    this.reactionCounts = const {},
    this.userReaction,
    this.commentCount = 0,
    this.isSaved = false,
    this.attendeeCount = 0,
    this.userRsvpStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'author_id': authorId,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'image_path': imagePath,
      'timestamp': timestamp.toIso8601String(),
      'space_id': spaceId,
      'pinned': pinned ? 1 : 0,
      'event_date': eventDate?.toIso8601String(),
      'event_location': eventLocation,
      'registration_link': registrationLink,
      'in_app_rsvp': inAppRsvp ? 1 : 0,
      'target_audience': targetAudience.join(','),
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map, {
    Map<String, int> reactions = const {},
    String? currentUserReaction,
    int comments = 0,
    bool saved = false,
    int attendees = 0,
    String? rsvpStatus,
  }) {
    final audienceStr = map['target_audience'] as String? ?? '';
    return PostModel(
      id: map['id'] as int?,
      authorId: map['author_id'] as int? ?? 0,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? 'achievement',
      category: map['category'] as String? ?? '',
      imagePath: map['image_path'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      spaceId: map['space_id'] as int?,
      pinned: (map['pinned'] as int? ?? 0) == 1,
      eventDate: map['event_date'] != null ? DateTime.parse(map['event_date'] as String) : null,
      eventLocation: map['event_location'] as String?,
      registrationLink: map['registration_link'] as String?,
      inAppRsvp: (map['in_app_rsvp'] as int? ?? 0) == 1,
      targetAudience: audienceStr.isNotEmpty ? audienceStr.split(',') : [],
      authorName: map['author_name'] as String?,
      authorRole: map['author_role'] as String?,
      authorAvatarIndex: map['author_avatar_index'] as int?,
      authorIsVerified: map['author_is_verified'] != null ? (map['author_is_verified'] as int) == 1 : null,
      authorSubtitle: map['author_subtitle'] as String?,
      reactionCounts: reactions,
      userReaction: currentUserReaction,
      commentCount: comments,
      isSaved: saved,
      attendeeCount: attendees,
      userRsvpStatus: rsvpStatus,
    );
  }

  PostModel copyWith({
    int? id,
    int? authorId,
    String? title,
    String? description,
    String? type,
    String? category,
    String? imagePath,
    DateTime? timestamp,
    int? spaceId,
    bool? pinned,
    DateTime? eventDate,
    String? eventLocation,
    String? registrationLink,
    bool? inAppRsvp,
    List<String>? targetAudience,
    String? authorName,
    String? authorRole,
    int? authorAvatarIndex,
    bool? authorIsVerified,
    String? authorSubtitle,
    Map<String, int>? reactionCounts,
    String? userReaction,
    int? commentCount,
    bool? isSaved,
    int? attendeeCount,
    String? userRsvpStatus,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      timestamp: timestamp ?? this.timestamp,
      spaceId: spaceId ?? this.spaceId,
      pinned: pinned ?? this.pinned,
      eventDate: eventDate ?? this.eventDate,
      eventLocation: eventLocation ?? this.eventLocation,
      registrationLink: registrationLink ?? this.registrationLink,
      inAppRsvp: inAppRsvp ?? this.inAppRsvp,
      targetAudience: targetAudience ?? this.targetAudience,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      authorAvatarIndex: authorAvatarIndex ?? this.authorAvatarIndex,
      authorIsVerified: authorIsVerified ?? this.authorIsVerified,
      authorSubtitle: authorSubtitle ?? this.authorSubtitle,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      userReaction: userReaction ?? this.userReaction,
      commentCount: commentCount ?? this.commentCount,
      isSaved: isSaved ?? this.isSaved,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      userRsvpStatus: userRsvpStatus ?? this.userRsvpStatus,
    );
  }
}
