import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../data/models/post_model.dart';
import '../../data/models/comment_model.dart';
import '../chat/chat_room_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  
  PostModel? _post;
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isFollowingAuthor = false;

  // Threading reply state
  CommentModel? _replyingToComment;

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetails() async {
    setState(() => _isLoading = true);
    final state = Provider.of<AppState>(context, listen: false);
    
    final postDetails = await state.getPostDetails(widget.postId);
    if (postDetails != null) {
      final commentsList = await state.getComments(widget.postId);
      final isFollowing = await state.getIsFollowing(postDetails.authorId);
      
      setState(() {
        _post = postDetails;
        _comments = commentsList;
        _isFollowingAuthor = isFollowing;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _post == null) return;

    final state = Provider.of<AppState>(context, listen: false);
    
    await state.addComment(
      _post!.id!,
      text,
      parentId: _replyingToComment?.id,
    );

    _commentController.clear();
    setState(() {
      _replyingToComment = null;
    });
    _commentFocusNode.unfocus();

    // Reload comments
    final commentsList = await state.getComments(_post!.id!);
    // Refresh post details to update comment count
    final updatedPost = await state.getPostDetails(_post!.id!);

    setState(() {
      _comments = commentsList;
      if (updatedPost != null) {
        _post = updatedPost;
      }
    });
  }

  void _startReply(CommentModel comment) {
    setState(() {
      _replyingToComment = comment;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
    });
    _commentFocusNode.unfocus();
  }

  Future<void> _toggleFollow() async {
    if (_post == null) return;
    final state = Provider.of<AppState>(context, listen: false);
    await state.toggleFollowUser(_post!.authorId);
    
    final isFollowing = await state.getIsFollowing(_post!.authorId);
    setState(() {
      _isFollowingAuthor = isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post Detail')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.aluNavy)),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post Not Found')),
        body: const Center(child: Text('This post has been deleted or is unavailable.')),
      );
    }

    final state = Provider.of<AppState>(context);
    final isOrganizer = _post!.type == 'opportunity';
    final isSelf = _post!.authorId == state.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOrganizer ? 'Opportunity Detail' : 'Achievement Detail'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Author profile header card
                  _buildAuthorHeader(isSelf),
                  const SizedBox(height: 16),
                  
                  // 2. Main content area
                  if (isOrganizer) ...[
                    _buildOpportunityContent(state)
                  ] else ...[
                    _buildAchievementContent(state)
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // 3. Comments section header
                  Row(
                    children: [
                      const Icon(Icons.mode_comment_outlined, size: 20, color: AppTheme.aluNavy),
                      const SizedBox(width: 8),
                      Text(
                        isOrganizer ? 'Q&A / Discussion (${_post!.commentCount})' : 'Comments (${_post!.commentCount})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.aluNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 4. Comments list (Reddit-style threading)
                  _comments.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Text(
                              'No comments yet. Be the first to reply!',
                              style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return _buildCommentThread(comment);
                          },
                        ),
                ],
              ),
            ),
          ),
          
          // 5. Reply context bar (shows up when replying to another comment)
          if (_replyingToComment != null) _buildReplyContextBar(),

          // 6. Bottom comment input field
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildAuthorHeader(bool isSelf) {
    return Row(
      children: [
        AppTheme.buildAvatar(_post!.authorName ?? '?', _post!.authorAvatarIndex ?? 0),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _post!.authorName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (_post!.authorIsVerified == true) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.blue, size: 14),
                  ]
                ],
              ),
              const SizedBox(height: 3),
              AppTheme.buildRoleBadge(_post!.authorRole ?? 'student', subtitle: _post!.authorSubtitle),
            ],
          ),
        ),
        
        // Follow / Following button (only for achievements of other people)
        if (!isSelf && _post!.type == 'achievement')
          TextButton(
            onPressed: _toggleFollow,
            style: TextButton.styleFrom(
              backgroundColor: _isFollowingAuthor ? AppTheme.background : AppTheme.aluNavy,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              _isFollowingAuthor ? 'Following' : 'Follow',
              style: TextStyle(
                color: _isFollowingAuthor ? AppTheme.textPrimary : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // Achievement Post Layout
  Widget _buildAchievementContent(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_post!.title.isNotEmpty) ...[
          Text(
            _post!.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.aluNavy),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          _post!.description,
          style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, height: 1.5),
        ),
        
        // GSoC Mock graphics
        if (_post!.id == 1) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.teal.shade700],
              ),
            ),
            child: const Center(
              child: Icon(Icons.laptop_chromebook, color: Colors.white, size: 60),
            ),
          ),
        ],
        
        const SizedBox(height: 20),
        const Divider(color: AppTheme.borderLight),
        const SizedBox(height: 12),
        
        // Tiered reactions
        Row(
          children: [
            _buildReactionChip('respect', '👏 Respect', _post!.reactionCounts['respect'] ?? 0, state),
            const SizedBox(width: 8),
            _buildReactionChip('impressive', '🔥 Impressive', _post!.reactionCounts['impressive'] ?? 0, state),
            const SizedBox(width: 8),
            _buildReactionChip('inspired', '🚀 Inspired', _post!.reactionCounts['inspired'] ?? 0, state),
          ],
        )
      ],
    );
  }

  Widget _buildReactionChip(String type, String label, int count, AppState state) {
    final isSelected = _post!.userReaction == type;
    
    return InkWell(
      onTap: () async {
        await state.reactToPost(_post!.id!, type);
        // Refresh detail state
        final updated = await state.getPostDetails(_post!.id!);
        if (updated != null) {
          setState(() {
            _post = updated;
          });
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.aluNavy.withOpacity(0.08) : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.aluNavy : Colors.transparent),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.aluNavy : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Opportunity Post Layout
  Widget _buildOpportunityContent(AppState state) {
    final isRsvped = _post!.userRsvpStatus == 'upcoming';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event title box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.aluNavy.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: const Border(left: BorderSide(color: AppTheme.aluRed, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _post!.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.aluNavy),
              ),
              const SizedBox(height: 12),
              
              // Date
              if (_post!.eventDate != null)
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.aluNavy),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('MMMM dd, yyyy - hh:mm a').format(_post!.eventDate!),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              
              // Location
              if (_post!.eventLocation != null)
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.aluNavy),
                    const SizedBox(width: 10),
                    Text(
                      _post!.eventLocation!,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // Attendee Count
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 16, color: AppTheme.aluNavy),
                  const SizedBox(width: 10),
                  Text(
                    '${_post!.attendeeCount} attending from ALU Network',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(
          _post!.description,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.5),
        ),
        
        // Target Audience Tags
        if (_post!.targetAudience.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Target Audience / Track Relevance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _post!.targetAudience.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 24),

        // RSVP and Event Chat actions
        Row(
          children: [
            if (_post!.inAppRsvp)
              Expanded(
                child: _buildOpportunityRsvpActionButton(state),
              )
            else if (_post!.registrationLink != null && _post!.registrationLink!.isNotEmpty)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening Link: ${_post!.registrationLink}')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.aluNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Register Externally', style: TextStyle(color: Colors.white)),
                ),
              ),
            
            // Event chat option (only if RSVPed)
            if (isRsvped) ...[
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        eventId: _post!.id!,
                        chatTitle: '${_post!.title} (Event Chat)',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                label: const Text('Event Chat', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.aluRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildOpportunityRsvpActionButton(AppState state) {
    final isRsvped = _post!.userRsvpStatus == 'upcoming';
    
    return ElevatedButton(
      onPressed: () async {
        if (isRsvped) {
          // Cancel RSVP dialog
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
                    await state.cancelEventRsvp(_post!.id!);
                    navigator.pop();
                    await _loadPostDetails();
                  },
                  child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        } else {
          final messenger = ScaffoldMessenger.of(context);
          await state.rsvpToEvent(_post!.id!, 'upcoming');
          messenger.showSnackBar(
            const SnackBar(content: Text('RSVP Registered! You have been auto-joined to the Event Chat.')),
          );
          await _loadPostDetails();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isRsvped ? Colors.green : AppTheme.aluNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        isRsvped ? 'Registered (Going)' : 'RSVP to Event',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Reddit-style Comment Thread Renderer
  Widget _buildCommentThread(CommentModel comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parent Comment Row
        _buildSingleCommentCard(comment, isChild: false),
        
        // Child Replies (One-level indented)
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Column(
              children: comment.replies.map((reply) {
                return _buildSingleCommentCard(reply, isChild: true);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleCommentCard(CommentModel comment, {required bool isChild}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isChild ? Colors.white : AppTheme.background.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: isChild ? Border.all(color: AppTheme.borderLight) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppTheme.buildAvatar(comment.authorName ?? '?', comment.authorAvatarIndex ?? 0, radius: 14),
              const SizedBox(width: 8),
              Text(
                comment.authorName ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  comment.authorRole?.toUpperCase() ?? 'STUDENT',
                  style: const TextStyle(fontSize: 8, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('hh:mm a').format(comment.timestamp),
                style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
          
          // Action row for comment (Reply triggers only for top-level parents)
          if (!isChild) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _startReply(comment),
                icon: const Icon(Icons.reply, size: 14, color: AppTheme.aluNavy),
                label: const Text('Reply', style: TextStyle(fontSize: 11, color: AppTheme.aluNavy)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildReplyContextBar() {
    return Container(
      color: AppTheme.aluNavy.withOpacity(0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 16, color: AppTheme.aluNavy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to @${_replyingToComment!.authorName}',
              style: const TextStyle(fontSize: 12, color: AppTheme.aluNavy, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, size: 18, color: AppTheme.textLight),
            onPressed: _cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              maxLines: null,
              decoration: InputDecoration(
                hintText: _replyingToComment != null ? 'Write a reply...' : 'Add a comment...',
                hintStyle: const TextStyle(fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                fillColor: AppTheme.background,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.aluNavy),
            onPressed: _submitComment,
          ),
        ],
      ),
    );
  }
}
