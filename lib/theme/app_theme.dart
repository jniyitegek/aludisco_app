import 'package:flutter/material.dart';

class AppTheme {
  // ALU Brand Colors
  static const Color aluNavy = Color(0xFF063162);
  static const Color aluRed = Color(0xFFB11E29);
  static const Color aluLightNavy = Color(0xFF1E4C82);
  static const Color aluCrimson = Color(0xFFC01F2B);
  
  // Neutral Colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color borderLight = Color(0xFFE2E8F0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: aluNavy,
        primary: aluNavy,
        secondary: aluRed,
        background: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: aluRed,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: aluNavy),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 15, height: 1.4),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14, height: 1.4),
        labelLarge: TextStyle(color: textLight, fontSize: 12, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: aluRed,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: aluNavy,
        unselectedItemColor: textLight,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // Get color for user avatar index
  static Color getAvatarColor(int index) {
    const colors = [
      Color(0xFFE53935), // Red
      Color(0xFF1E88E5), // Blue
      Color(0xFF43A047), // Green
      Color(0xFF8E24AA), // Purple
      Color(0xFFF4511E), // Orange
      Color(0xFF00ACC1), // Cyan
      Color(0xFF3949AB), // Indigo
      Color(0xFF00897B), // Teal
    ];
    return colors[index % colors.length];
  }

  // Draw initials inside a colored circle as a premium fallback avatar
  static Widget buildAvatar(String name, int avatarIndex, {double radius = 22}) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join('').toUpperCase()
        : 'U';
    
    // Specially seed user 2 (ALU Tech Club) to show a community group icon
    if (name.toLowerCase().contains('club') || name.toLowerCase().contains('organizer')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: aluRed,
        child: Icon(Icons.groups, color: Colors.white, size: radius * 1.1),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: getAvatarColor(avatarIndex),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  // Visual helper for badge widgets
  static Widget buildRoleBadge(String role, {String? subtitle}) {
    Color badgeColor;
    String badgeText = role.toUpperCase();
    
    switch (role.toLowerCase()) {
      case 'student':
        badgeColor = aluNavy;
        break;
      case 'alumni':
        badgeColor = const Color(0xFF4A5568);
        break;
      case 'organizer':
        badgeColor = aluRed;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 11,
            ),
          ),
        ]
      ],
    );
  }
}
