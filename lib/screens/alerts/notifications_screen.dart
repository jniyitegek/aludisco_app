import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../data/models/notification_model.dart';
import '../home/post_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when opening this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).markAllNotificationsRead();
    });
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'reaction':
        return Icons.favorite_outline;
      case 'follow':
        return Icons.person_add_outlined;
      case 'opportunity':
        return Icons.event_note_outlined;
      case 'reply':
        return Icons.mode_comment_outlined;
      case 'event_reminder':
        return Icons.access_time_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'reaction':
        return Colors.orange;
      case 'follow':
        return AppTheme.aluNavy;
      case 'opportunity':
        return AppTheme.aluRed;
      case 'reply':
        return Colors.blue;
      case 'event_reminder':
        return Colors.green;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final notifications = state.notifications;
    
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Alerts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.aluNavy,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Stay updated on reactions, mentions, RSVPs, and mentorship connections.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return _buildNotificationCard(context, notif);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.textLight),
          SizedBox(height: 16),
          Text(
            'All quiet here.',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8),
          Text('We will notify you when things happen!', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notif) {
    final timeStr = DateFormat('MMM dd, hh:mm a').format(notif.timestamp);
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notif.isRead ? AppTheme.borderLight : AppTheme.aluNavy.withOpacity(0.2),
          width: notif.isRead ? 1 : 1.5,
        ),
      ),
      color: notif.isRead ? Colors.white : AppTheme.aluNavy.withOpacity(0.02),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            AppTheme.buildAvatar(notif.senderName ?? '?', notif.senderAvatarIndex ?? 0, radius: 18),
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: _getColorForType(notif.type),
                child: Icon(
                  _getIconForType(notif.type),
                  size: 10,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
        title: Text(
          notif.message,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            timeStr,
            style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
          ),
        ),
        trailing: notif.postId != null 
            ? const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textLight)
            : null,
        onTap: notif.postId != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(postId: notif.postId!),
                  ),
                );
              }
            : null,
      ),
    );
  }
}
