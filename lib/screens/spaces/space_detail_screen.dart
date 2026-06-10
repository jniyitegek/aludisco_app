import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../data/models/space_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/message_model.dart';
import '../home/home_feed_screen.dart';

class SpaceDetailScreen extends StatefulWidget {
  final SpaceModel space;

  const SpaceDetailScreen({super.key, required this.space});

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<PostModel> _spacePosts = [];
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChange);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    final state = Provider.of<AppState>(context, listen: false);
    
    if (state.currentUser != null) {
      await state.loadFeed();
      final posts = state.feedPosts.where((p) => p.spaceId == widget.space.id).toList();
      setState(() {
        _spacePosts = posts;
        _isLoadingPosts = false;
      });
    } else {
      setState(() => _isLoadingPosts = false);
    }
  }

  void _onTabChange() {
    if (_tabController.index == 1) {
      // Load space chat messages
      final state = Provider.of<AppState>(context, listen: false);
      state.loadSpaceMessages(widget.space.id!);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final state = Provider.of<AppState>(context, listen: false);
    await state.sendChatMessage(
      spaceId: widget.space.id!,
      content: text,
    );

    _msgController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.space.name, style: const TextStyle(color: AppTheme.aluNavy, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.aluRed,
          indicatorWeight: 3,
          labelColor: AppTheme.aluNavy,
          unselectedLabelColor: AppTheme.textLight,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Discussion Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Posts Tab
          _isLoadingPosts
              ? const Center(child: CircularProgressIndicator(color: AppTheme.aluNavy))
              : _spacePosts.isEmpty
                  ? _buildEmptyPostsView()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _spacePosts.length,
                      itemBuilder: (context, index) {
                        return FeedCard(post: _spacePosts[index]);
                      },
                    ),
                    
          // Discussion Chat Tab
          Column(
            children: [
              Expanded(
                child: state.activeChatMessages.isEmpty
                    ? _buildEmptyChatView()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.activeChatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = state.activeChatMessages[index];
                          return _buildChatMessageCard(msg, state);
                        },
                      ),
              ),
              
              // Chat input bar
              _buildChatInputBar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPostsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.feed_outlined, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            'No posts in ${widget.space.name} yet.',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text('Tap the "+" button to share the first post!', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyChatView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.textLight),
          SizedBox(height: 16),
          Text(
            'Start the discussion!',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8),
          Text('Say hello to the space.', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChatMessageCard(MessageModel msg, AppState state) {
    final isMe = msg.senderId == state.currentUser?.id;
    final timeStr = DateFormat('hh:mm a').format(msg.timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.aluNavy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: isMe ? null : Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTheme.buildAvatar(msg.senderName ?? '?', msg.senderAvatarIndex ?? 0, radius: 10),
                  const SizedBox(width: 6),
                  Text(
                    msg.senderName ?? '',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.aluNavy),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              msg.content,
              style: TextStyle(
                color: isMe ? Colors.white : AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeStr,
                style: TextStyle(
                  color: isMe ? Colors.white60 : AppTheme.textLight,
                  fontSize: 8,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChatInputBar() {
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
              controller: _msgController,
              decoration: InputDecoration(
                hintText: 'Type a message in ${widget.space.name}...',
                hintStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                fillColor: AppTheme.background,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.aluNavy),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
