import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../data/models/user_model.dart';
import '../../data/models/post_model.dart';
import '../../data/database_helper.dart';
import '../chat/chat_room_screen.dart';
import '../home/home_feed_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId; // If null, loads current user profile

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  UserModel? _profileUser;
  Map<String, int> _stats = {'followers': 0, 'following': 0, 'reactions_received': 0};
  List<PostModel> _userPosts = [];
  List<PostModel> _userRsvps = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isMutual = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final state = Provider.of<AppState>(context, listen: false);
    
    // Resolve user ID
    final int resolvedId = widget.userId ?? state.currentUser?.id ?? 0;
    
    // Fetch profile details
    final DatabaseHelper dbHelper = DatabaseHelper.instance;
    final user = await dbHelper.getUserById(resolvedId);

    if (user != null) {
      final userStats = await dbHelper.getUserStats(resolvedId);
      final posts = await state.getUserPosts(resolvedId);
      final rsvps = await state.getUserRsvps(resolvedId);
      
      bool following = false;
      bool mutual = false;
      
      if (state.currentUser != null && resolvedId != state.currentUser!.id) {
        following = await state.getIsFollowing(resolvedId);
        // Check if mutual: other user also follows current user
        final otherFollowsMe = await dbHelper.isFollowing(resolvedId, state.currentUser!.id!);
        mutual = following && otherFollowsMe;
      }

      setState(() {
        _profileUser = user;
        _stats = userStats;
        _userPosts = posts;
        _userRsvps = rsvps;
        _isFollowing = following;
        _isMutual = mutual;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.aluNavy));
    }

    if (_profileUser == null) {
      return const Center(child: Text('User profile not found.'));
    }

    final state = Provider.of<AppState>(context);
    final isSelf = _profileUser!.id == state.currentUser?.id;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Profile Header Info
                  _buildProfileHeaderCard(isSelf),
                  
                  // Profile Stats Bar
                  _buildStatsBar(),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                pinned: true,
                floating: false,
                toolbarHeight: 0,
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.aluRed,
                  indicatorWeight: 3,
                  labelColor: AppTheme.aluNavy,
                  unselectedLabelColor: AppTheme.textLight,
                  tabs: [
                    const Tab(text: 'Timeline'),
                    Tab(text: isSelf ? 'My Activities' : 'RSVPs'),
                    const Tab(text: 'About'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Timeline Tab (posts list)
            _buildTimelineTab(),

            // RSVP Activities Tab
            _buildActivitiesTab(state),

            // About Tab
            _buildAboutTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(bool isSelf) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTheme.buildAvatar(_profileUser!.name, _profileUser!.avatarIndex, radius: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _profileUser!.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.aluNavy),
                        ),
                        if (_profileUser!.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    AppTheme.buildRoleBadge(
                      _profileUser!.role,
                      subtitle: _profileUser!.role == 'student'
                          ? 'Class of ${_profileUser!.currentYear}'
                          : (_profileUser!.role == 'alumni' ? 'Class of ${_profileUser!.graduationYear}' : 'Organizer'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _profileUser!.bio,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action Buttons Row (Edit profile or Follow & DM)
          Row(
            children: [
              if (isSelf) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                      _loadProfileData(); // Reload stats/bio
                    },
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.aluNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ] else ...[
                // Follow Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final state = Provider.of<AppState>(context, listen: false);
                      await state.toggleFollowUser(_profileUser!.id!);
                      _loadProfileData(); // Reload following state/stats
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing ? AppTheme.background : AppTheme.aluNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: _isFollowing ? const BorderSide(color: AppTheme.borderLight) : null,
                    ),
                    child: Text(
                      _isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: _isFollowing ? AppTheme.textPrimary : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // DM Launcher (Mutual Gate check)
                Container(
                  decoration: BoxDecoration(
                    color: _isMutual ? AppTheme.aluNavy.withOpacity(0.06) : AppTheme.background,
                    border: Border.all(color: _isMutual ? AppTheme.aluNavy : AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isMutual ? Icons.chat_bubble : Icons.lock, 
                      color: _isMutual ? AppTheme.aluNavy : AppTheme.textLight,
                    ),
                    onPressed: () {
                      if (_isMutual) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomScreen(
                              receiverId: _profileUser!.id!,
                              chatTitle: _profileUser!.name,
                            ),
                          ),
                        );
                      } else {
                        _showDMGatedInfo();
                      }
                    },
                  ),
                )
              ]
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Followers', _stats['followers'] ?? 0),
          Container(width: 1, height: 24, color: AppTheme.borderLight),
          _buildStatItem('Following', _stats['following'] ?? 0),
          Container(width: 1, height: 24, color: AppTheme.borderLight),
          _buildStatItem('Reactions Received', _stats['reactions_received'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.aluNavy),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  // Sub Tab 1: TIMELINE (posts)
  Widget _buildTimelineTab() {
    if (_userPosts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No posts shared yet.', style: TextStyle(color: AppTheme.textLight)),
        ),
      );
    }

    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = _userPosts[index];
                  return Column(
                    children: [
                      if (post.pinned)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.push_pin, size: 12, color: AppTheme.aluRed),
                              const SizedBox(width: 4),
                              Text('Pinned Milestone', style: TextStyle(color: AppTheme.aluRed, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      FeedCard(post: post),
                    ],
                  );
                },
                childCount: _userPosts.length,
              ),
            ),
          ],
        );
      },
    );
  }

  // Sub Tab 2: ACTIVITIES / RSVPs (RSVP manager)
  Widget _buildActivitiesTab(AppState state) {
    if (_userRsvps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No RSVP activities listed.', style: TextStyle(color: AppTheme.textLight)),
        ),
      );
    }

    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final rsvpPost = _userRsvps[index];
                  final isUpcoming = rsvpPost.userRsvpStatus == 'upcoming';
                  final dateStr = rsvpPost.eventDate != null 
                      ? DateFormat('MMM dd, yyyy').format(rsvpPost.eventDate!) 
                      : '';
                      
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.borderLight),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUpcoming ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rsvpPost.userRsvpStatus?.toUpperCase() ?? 'UPCOMING',
                          style: TextStyle(
                            color: isUpcoming ? Colors.green : Colors.grey,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(rsvpPost.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('$dateStr • ${rsvpPost.eventLocation ?? ""}', style: const TextStyle(fontSize: 11)),
                      ),
                      trailing: isUpcoming
                          ? TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Cancel RSVP'),
                                    content: const Text('Are you sure you want to cancel your RSVP?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          final navigator = Navigator.of(context);
                                          await state.cancelEventRsvp(rsvpPost.id!);
                                          navigator.pop();
                                          _loadProfileData();
                                        },
                                        child: const Text('Cancel RSVP', style: TextStyle(color: Colors.red)),
                                      )
                                    ],
                                  ),
                                );
                              },
                              child: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 11)),
                            )
                          : null,
                    ),
                  );
                },
                childCount: _userRsvps.length,
              ),
            ),
          ],
        );
      },
    );
  }

  // Sub Tab 3: ABOUT
  Widget _buildAboutTab() {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Goal section
                  const Text('Current Goal / Focus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.aluNavy)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      _profileUser!.goal.isNotEmpty ? _profileUser!.goal : 'No goal specified yet.',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Skills tags
                  const Text('Skills & Focus Tags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.aluNavy)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _profileUser!.skills.map((skill) {
                      return Chip(
                        label: Text(skill),
                        backgroundColor: Colors.white,
                        labelStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        side: const BorderSide(color: AppTheme.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Links section
                  const Text('Professional Directory Links', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.aluNavy)),
                  const SizedBox(height: 8),
                  _buildLinkTile(Icons.code, 'GitHub', _profileUser!.github),
                  _buildLinkTile(Icons.link, 'LinkedIn', _profileUser!.linkedin),
                  _buildLinkTile(Icons.language, 'Portfolio', _profileUser!.portfolio),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLinkTile(IconData icon, String platform, String url) {
    final hasUrl = url.isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: hasUrl ? AppTheme.aluNavy : AppTheme.textLight),
      title: Text(platform, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(hasUrl ? url : 'Not linked yet', style: TextStyle(fontSize: 11, color: hasUrl ? Colors.blue : AppTheme.textLight)),
      trailing: hasUrl ? const Icon(Icons.open_in_new, size: 14, color: Colors.blue) : null,
      onTap: hasUrl
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening $platform Link: $url')),
              );
            }
          : null,
    );
  }

  void _showDMGatedInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppTheme.aluNavy),
            SizedBox(width: 10),
            Text('Direct Messaging Gated'),
          ],
        ),
        content: Text(
          'To prevent spam in the ALU community, you can only message ${_profileUser!.name} once both of you follow each other (mutual connections).'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}
