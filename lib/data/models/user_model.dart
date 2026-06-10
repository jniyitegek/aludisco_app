class UserModel {
  final int? id;
  final String email;
  final String name;
  final String role; // 'student', 'alumni', 'organizer'
  final String bio;
  final List<String> skills;
  final String goal;
  final String github;
  final String linkedin;
  final String portfolio;
  final int avatarIndex;
  final int? graduationYear;
  final String? cohort;
  final int? currentYear;
  final String? major;
  final bool isVerified;

  UserModel({
    this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.bio,
    required this.skills,
    required this.goal,
    required this.github,
    required this.linkedin,
    required this.portfolio,
    required this.avatarIndex,
    this.graduationYear,
    this.cohort,
    this.currentYear,
    this.major,
    required this.isVerified,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'name': name,
      'role': role,
      'bio': bio,
      'skills': skills.join(','),
      'goal': goal,
      'github': github,
      'linkedin': linkedin,
      'portfolio': portfolio,
      'avatar_index': avatarIndex,
      'graduation_year': graduationYear,
      'cohort': cohort,
      'current_year': currentYear,
      'major': major,
      'is_verified': isVerified ? 1 : 0,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? 'student',
      bio: map['bio'] as String? ?? '',
      skills: (map['skills'] as String? ?? '').isNotEmpty
          ? (map['skills'] as String).split(',')
          : [],
      goal: map['goal'] as String? ?? '',
      github: map['github'] as String? ?? '',
      linkedin: map['linkedin'] as String? ?? '',
      portfolio: map['portfolio'] as String? ?? '',
      avatarIndex: map['avatar_index'] as int? ?? 0,
      graduationYear: map['graduation_year'] as int?,
      cohort: map['cohort'] as String?,
      currentYear: map['current_year'] as int?,
      major: map['major'] as String?,
      isVerified: (map['is_verified'] as int? ?? 0) == 1,
    );
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? name,
    String? role,
    String? bio,
    List<String>? skills,
    String? goal,
    String? github,
    String? linkedin,
    String? portfolio,
    int? avatarIndex,
    int? graduationYear,
    String? cohort,
    int? currentYear,
    String? major,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      goal: goal ?? this.goal,
      github: github ?? this.github,
      linkedin: linkedin ?? this.linkedin,
      portfolio: portfolio ?? this.portfolio,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      graduationYear: graduationYear ?? this.graduationYear,
      cohort: cohort ?? this.cohort,
      currentYear: currentYear ?? this.currentYear,
      major: major ?? this.major,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
