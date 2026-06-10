class SpaceModel {
  final int? id;
  final String name; // e.g. '#startups'
  final String description;
  final String iconName; // e.g. 'work', 'rocket_launch'

  SpaceModel({
    this.id,
    required this.name,
    required this.description,
    required this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'icon': iconName,
    };
  }

  factory SpaceModel.fromMap(Map<String, dynamic> map) {
    return SpaceModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconName: map['icon'] as String? ?? 'group',
    );
  }
}
