import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../data/models/message_model.dart';

class ChatRoomScreen extends StatefulWidget {
  final int? receiverId; // for 1:1 DMs
  final int? eventId;    // for event chats
  final int? spaceId;    // for space chats
  final String chatTitle;

  const ChatRoomScreen({
    super.key,
    this.receiverId,
    this.eventId,
    this.spaceId,
    required this.chatTitle,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    final state = Provider.of<AppState>(context, listen: false);
    if (widget.spaceId != null) {
      state.loadSpaceMessages(widget.spaceId!);
    } else if (widget.eventId != null) {
      state.loadEventMessages(widget.eventId!);
    } else if (widget.receiverId != null) {
      state.loadDirectMessages(widget.receiverId!);
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
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
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final state = Provider.of<AppState>(context, listen: false);
    await state.sendChatMessage(
      receiverId: widget.receiverId,
      eventId: widget.eventId,
      spaceId: widget.spaceId,
      content: text,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final messages = state.activeChatMessages;
    final isDm = widget.receiverId != null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatTitle,
              style: const TextStyle(color: AppTheme.aluNavy, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              isDm ? 'Direct Message (Mutuals)' : (widget.eventId != null ? 'Event Group Chat' : 'Space Discussion'),
              style: const TextStyle(color: AppTheme.textLight, fontSize: 10),
            ),
          ],
        ),
      ),
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Message List
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _buildMessageBubble(msg, state);
                    },
                  ),
          ),
          
          // Chat input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum_outlined, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            widget.receiverId != null ? 'No messages here yet.' : 'Welcome to the group chat!',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            widget.receiverId != null ? 'Say hi to start the conversation.' : 'Be the first to share something!',
            style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, AppState state) {
    final isMe = msg.senderId == state.currentUser?.id;
    final timeStr = DateFormat('hh:mm a').format(msg.timestamp);

    // Custom system message check (e.g. "has joined the event chat!")
    final isSystemMessage = msg.content.contains('has joined the event chat!');

    if (isSystemMessage) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.borderLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${msg.senderName} ${msg.content}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

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

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
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
