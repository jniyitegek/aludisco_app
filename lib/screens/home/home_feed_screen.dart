import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../data/models/post_model.dart';
import 'post_detail_screen.dart';
import '../profile/profile_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final state = Provider.of<AppState>(context, listen: false);
    if (_tabController.index == 0) {
      state.setFeedTab('for_you');
    } else {
      state.setFeedTab('network');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    
    return Column(
      children: [
        // Tab Header matching Image 2
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.aluRed,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            labelColor: AppTheme.aluNavy,
            unselectedLabelColor: AppTheme.textLight,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            tabs: const [
              Tab(text: 'For You'),
              Tab(text: 'ALU Network'),
            ],
          ),
        ),
        
        // Feed List
        Expanded(
          child: state.isLoading && state.feedPosts.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppTheme.aluNavy))
              : RefreshIndicator(
                  onRefresh: () => state.loadFeed(),
                  color: AppTheme.aluNavy,
                  child: state.feedPosts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: state.feedPosts.length,
                          itemBuilder: (context, index) {
                            final post = state.feedPosts[index];
                            return FeedCard(post: post);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Column(
            children: [
              Icon(Icons.feed_outlined, size: 64, color: AppTheme.textLight),
              SizedBox(height: 16),
              Text(
                'No posts here yet.',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
              SizedBox(height: 8),
              Text(
                'Share an achievement or join spaces to start!',
                style: TextStyle(color: AppTheme.textLight, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Reusable Feed Card
class FeedCard extends StatelessWidget {
  final PostModel post;

  const FeedCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: post.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Author Row
              Row(
                children: [
                  // Author avatar tap to visit profile
                  InkWell(
                    onTap: () => _navigateToProfile(context, post.authorId),
                    child: AppTheme.buildAvatar(post.authorName ?? '?', post.authorAvatarIndex ?? 0),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.authorName ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (post.authorIsVerified == true) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.blue, size: 14),
                            ]
                          ],
                        ),
                        const SizedBox(height: 3),
                        AppTheme.buildRoleBadge(post.authorRole ?? 'student', subtitle: post.authorSubtitle),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      post.type == 'opportunity' ? Icons.share_outlined : Icons.more_vert, 
                      color: AppTheme.textLight,
                      size: 20,
                    ),
                    onPressed: () {
                      if (post.type == 'opportunity') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opportunity link copied to clipboard!')),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 2. Post Content
              if (post.type == 'achievement') ...[
                // Achievement Styling
                if (post.title.isNotEmpty) ...[
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.aluNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  post.description,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
                ),
                
                // Show mockup GSoC image if ID is 1 (matching GSoC card in Image 2)
                if (post.id == 1) ...[
                  const SizedBox(height: 12),
                  _buildGsocMockImage(),
                ],
                
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 12),
                
                // Achievement Reactions & Comments Row
                Row(
                  children: [
                    _buildReactionButton(context, 'respect', '👏', post.reactionCounts['respect'] ?? 0),
                    _buildReactionButton(context, 'impressive', '🔥', post.reactionCounts['impressive'] ?? 0),
                    _buildReactionButton(context, 'inspired', '🚀', post.reactionCounts['inspired'] ?? 0),
                    const Spacer(),
                    
                    // Comments Badge
                    Row(
                      children: [
                        const Icon(Icons.mode_comment_outlined, size: 16, color: AppTheme.textLight),
                        const SizedBox(width: 6),
                        Text(
                          '${post.commentCount} comments',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Saved Icon
                    IconButton(
                      icon: Icon(
                        post.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                        color: post.isSaved ? AppTheme.aluNavy : AppTheme.textLight,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => state.toggleSavePost(post.id!),
                    ),
                  ],
                ),
              ] else ...[
                // Opportunity Card (Matches Image 2 nested style)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      left: BorderSide(color: AppTheme.aluRed, width: 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.aluNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Event Date with calendar icon
                      if (post.eventDate != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM dd, yyyy').format(post.eventDate!),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      Text(
                        post.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Opportunity Footer Actions: RSVP Now & Save
                Row(
                  children: [
                    if (post.inAppRsvp)
                      Expanded(
                        child: _buildRsvpButton(context, state),
                      )
                    else if (post.registrationLink != null && post.registrationLink!.isNotEmpty)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Opening registration link: ${post.registrationLink}')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.aluNavy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Register Now', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      ),
                    const SizedBox(width: 12),
                    
                    // Bookmark icon button (outline box shape)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.aluNavy, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(
                          post.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                          color: AppTheme.aluNavy,
                          size: 20,
                        ),
                        onPressed: () => state.toggleSavePost(post.id!),
                      ),
                    )
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Google Summer of Code premium mockup container
  Widget _buildGsocMockImage() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.laptop_chromebook, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text(
                  'Google Summer of Code',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 4),
                Text(
                  'Student Developer 2024',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(BuildContext context, String type, String emoji, int count) {
    final state = Provider.of<AppState>(context, listen: false);
    final isSelected = post.userReaction == type;
    
    return InkWell(
      onTap: () => state.reactToPost(post.id!, type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.aluNavy.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: AppTheme.aluNavy, width: 1) : null,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.aluNavy : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRsvpButton(BuildContext context, AppState state) {
    final isRsvped = post.userRsvpStatus == 'upcoming';
    
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: () {
          if (isRsvped) {
            // Confirm cancel RSVP
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel RSVP'),
                content: const Text('Are you sure you want to cancel your registration for this event?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      state.cancelEventRsvp(post.id!);
                      Navigator.pop(context);
                    },
                    child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          } else {
            state.rsvpToEvent(post.id!, 'upcoming');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('RSVP Successful! Auto-joined the Event Chat.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isRsvped ? Colors.green : AppTheme.aluNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isRsvped) ...[
              const Icon(Icons.check, color: Colors.white, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              isRsvped ? 'Registered (Going)' : 'RSVP Now',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context, int authorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: ProfileScreen(userId: authorId),
        ),
      ),
    );
  }
}
