import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import 'home/home_feed_screen.dart';
import 'spaces/spaces_screen.dart';
import 'post/create_post_screen.dart';
import 'alerts/notifications_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load initial app data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).reloadAllData();
    });
  }

  // List of screens corresponding to bottom navigation tabs
  final List<Widget> _screens = [
    const HomeFeedScreen(),
    const SpacesScreen(),
    const SizedBox(), // Placeholder for Post button (trigger modal)
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  void _onTabSelect(int index) {
    if (index == 2) {
      // Open Create Post as a Modal / Bottom sheet or page
      _showCreatePostOptions();
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _showCreatePostOptions() {
    final currentUser = Provider.of<AppState>(context, listen: false).currentUser;
    final isOrganizer = currentUser?.role == 'organizer';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Share with ALU Community',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.aluNavy,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Achievement post option
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.background,
                    child: Icon(Icons.workspace_premium, color: AppTheme.aluNavy),
                  ),
                  title: const Text('Share Achievement Post', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Celebrate a career win, project launch, or skills milestone.'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePostScreen(initialType: 'achievement'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                // Opportunity post option
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isOrganizer ? AppTheme.background : Colors.grey.shade100,
                    child: Icon(
                      Icons.event_note, 
                      color: isOrganizer ? AppTheme.aluRed : Colors.grey,
                    ),
                  ),
                  title: Text(
                    'Post Opportunity', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOrganizer ? AppTheme.textPrimary : Colors.grey,
                    ),
                  ),
                  subtitle: Text(
                    'Events, hackathons, workshops, and internships.',
                    style: TextStyle(color: isOrganizer ? AppTheme.textSecondary : Colors.grey.shade400),
                  ),
                  trailing: !isOrganizer 
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('ORGANIZERS ONLY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                        )
                      : null,
                  onTap: isOrganizer
                      ? () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreatePostScreen(initialType: 'opportunity'),
                            ),
                          );
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Only verified ALU Club Leaders / Organizers can post opportunities.')),
                          );
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Custom text branding
            const Text(
              'ALUDISCO',
              style: TextStyle(
                color: AppTheme.aluRed,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            if (appState.hasUpcomingEventReminder) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.aluNavy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time, size: 10, color: Colors.white),
                    SizedBox(width: 3),
                    Text('Reminder', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ]
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.aluNavy, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex, // handle post modal index
        children: _screens,
      ),
      
      // Floating Action Button for Post creation (matches red circle in Image 2)
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showCreatePostOptions,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
          
      // Custom High Fidelity Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            )
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.groups_rounded, 'Spaces'),
                _buildNavItem(2, Icons.add_box_rounded, 'Post'),
                _buildNavItem(
                  3, 
                  Icons.notifications_rounded, 
                  'Alerts', 
                  badgeCount: appState.unreadNotificationsCount,
                ),
                _buildNavItem(4, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    final isSelected = _currentIndex == index;
    
    if (isSelected) {
      // Selected State: Blue rounded pill matching Image 2
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.aluNavy,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    // Unselected State
    return InkWell(
      onTap: () => _onTabSelect(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppTheme.textLight, size: 20),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.aluRed,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
