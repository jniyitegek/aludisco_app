import 'dart:io';
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/models/user_model.dart';
import '../data/models/post_model.dart';
import '../data/models/comment_model.dart';
import '../data/models/space_model.dart';
import '../data/models/message_model.dart';
import '../data/models/notification_model.dart';

class AppState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  UserModel? _currentUser;
  List<PostModel> _feedPosts = [];
  List<SpaceModel> _spaces = [];
  List<NotificationModel> _notifications = [];
  int _unreadNotificationsCount = 0;
  List<UserModel> _mutuals = [];
  bool _isLoading = false;
  String _currentFeedTab = 'for_you'; // 'for_you' or 'network'
  String _searchQuery = '';

  // Active chat streams (simulated via manual refreshing or timer)
  List<MessageModel> _activeChatMessages = [];

  // Getters
  UserModel? get currentUser => _currentUser;
  List<PostModel> get feedPosts => _feedPosts;
  List<SpaceModel> get spaces => _spaces;
  List<NotificationModel> get notifications => _notifications;
  int get unreadNotificationsCount => _unreadNotificationsCount;
  List<UserModel> get mutuals => _mutuals;
  bool get isLoading => _isLoading;
  String get currentFeedTab => _currentFeedTab;
  String get searchQuery => _searchQuery;
  List<MessageModel> get activeChatMessages => _activeChatMessages;

  // Check if there are any RSVPs within 48 hours
  bool get hasUpcomingEventReminder {
    if (_currentUser == null) return false;
    // Look through feed/rsvps
    final now = DateTime.now();
    for (var post in _feedPosts) {
      if (post.type == 'opportunity' && post.userRsvpStatus == 'upcoming' && post.eventDate != null) {
        final diff = post.eventDate!.difference(now);
        if (diff.inHours >= 0 && diff.inHours <= 48) {
          return true;
        }
      }
    }
    return false;
  }

  // Init & Session Management
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // Check if we are running in a widget/unit test to bypass SQLite opening
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    await _db.database; // Ensure db is initialized

    // Try to load previously logged-in session user
    final savedUser = await _db.getLoggedInUser();
    if (savedUser != null) {
      _currentUser = savedUser;
      await reloadAllData();
    } else {
      // Default auto-log in for first-time simulator boot
      await login('dkuzo@alustudent.com');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email) async {
    _isLoading = true;
    notifyListeners();

    final user = await _db.getUserByEmail(email);
    if (user != null) {
      _currentUser = user;
      await _db.setLoggedInUser(user.id!); // Store session
      await reloadAllData();
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> signup(UserModel user) async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _db.registerUser(user);
    await _db.setLoggedInUser(_currentUser!.id!); // Store session
    await reloadAllData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _db.clearLoggedInUser(); // Clear session
    _currentUser = null;
    _feedPosts = [];
    _notifications = [];
    _unreadNotificationsCount = 0;
    _mutuals = [];
    notifyListeners();
  }

  Future<void> reloadAllData() async {
    if (_currentUser == null) return;
    await loadFeed();
    await loadSpaces();
    await loadNotifications();
    await loadMutuals();
  }

  // Feed management
  Future<void> loadFeed({String? search}) async {
    if (_currentUser == null) return;
    _isLoading = true;
    if (search != null) _searchQuery = search;

    _feedPosts = await _db.getFeedPosts(
      _currentUser!.id!,
      tab: _currentFeedTab,
      search: _searchQuery,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setFeedTab(String tab) async {
    if (_currentFeedTab == tab) return;
    _currentFeedTab = tab;
    await loadFeed();
  }

  Future<void> setFeedSearch(String query) async {
    _searchQuery = query;
    await loadFeed();
  }

  // Reactions & Posts
  Future<void> reactToPost(int postId, String reactionType) async {
    if (_currentUser == null) return;
    final currentReact = _feedPosts.firstWhere((p) => p.id == postId).userReaction;

    if (currentReact == reactionType) {
      // Remove reaction if clicked same
      await _db.removeReaction(postId, _currentUser!.id!);
    } else {
      await _db.addReaction(postId, _currentUser!.id!, reactionType);
    }

    // Refresh only this post in feed to keep scrolling position
    final updatedPost = await _db.getPostDetails(postId, _currentUser!.id!);
    if (updatedPost != null) {
      final index = _feedPosts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _feedPosts[index] = updatedPost;
        notifyListeners();
      }
    }
  }

  Future<void> toggleSavePost(int postId) async {
    if (_currentUser == null) return;
    await _db.toggleSavePost(postId, _currentUser!.id!);

    // Refresh this post in feed
    final updatedPost = await _db.getPostDetails(postId, _currentUser!.id!);
    if (updatedPost != null) {
      final index = _feedPosts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _feedPosts[index] = updatedPost;
        notifyListeners();
      }
    }
  }

  Future<PostModel?> getPostDetails(int postId) async {
    if (_currentUser == null) return null;
    return await _db.getPostDetails(postId, _currentUser!.id!);
  }

  Future<void> createPost({
    required String title,
    required String description,
    required String type,
    required String category,
    int? spaceId,
    DateTime? eventDate,
    String? eventLocation,
    String? registrationLink,
    bool inAppRsvp = false,
    List<String> targetAudience = const [],
  }) async {
    if (_currentUser == null) return;

    final newPost = PostModel(
      authorId: _currentUser!.id!,
      title: title,
      description: description,
      type: type,
      category: category,
      timestamp: DateTime.now(),
      spaceId: spaceId,
      pinned: false,
      eventDate: eventDate,
      eventLocation: eventLocation,
      registrationLink: registrationLink,
      inAppRsvp: inAppRsvp,
      targetAudience: targetAudience,
    );

    await _db.insertPost(newPost);
    await loadFeed();

    // If it's an opportunity, notify relevant students matching the target tags
    if (type == 'opportunity') {
      // Trigger notifications to other matching users
      // In a real app we'd query matching skills; here we can push a mock notification to Alice/Bob
      final dbInstance = await _db.database;
      final allUserMaps = await dbInstance.query('users');
      for (var uMap in allUserMaps) {
        final uId = uMap['id'] as int;
        if (uId != _currentUser!.id) {
          await _db.insertNotification(NotificationModel(
            userId: uId,
            senderId: _currentUser!.id!,
            type: 'opportunity',
            message: 'New Opportunity in your interest area: $title',
            isRead: false,
            timestamp: DateTime.now(),
          ));
        }
      }
      await loadNotifications();
    }
  }

  // RSVPs
  Future<void> rsvpToEvent(int postId, String status) async {
    if (_currentUser == null) return;
    await _db.rsvpToEvent(postId, _currentUser!.id!, status);
    
    // Auto-join event chat & post a join message
    await _db.insertMessage(MessageModel(
      senderId: _currentUser!.id!,
      eventId: postId,
      content: 'has joined the event chat!',
      timestamp: DateTime.now(),
    ));

    // Refresh feed & notify
    await loadFeed();
  }

  Future<void> cancelEventRsvp(int postId) async {
    if (_currentUser == null) return;
    await _db.cancelRsvp(postId, _currentUser!.id!);
    
    // Refresh feed & notify
    await loadFeed();
  }

  // Comments
  Future<List<CommentModel>> getComments(int postId) async {
    return await _db.getComments(postId);
  }

  Future<void> addComment(int postId, String content, {int? parentId}) async {
    if (_currentUser == null) return;
    final comment = CommentModel(
      postId: postId,
      authorId: _currentUser!.id!,
      content: content,
      parentId: parentId,
      timestamp: DateTime.now(),
    );
    await _db.insertComment(comment);
    
    // Refresh feed (to update comment count badge)
    final updatedPost = await _db.getPostDetails(postId, _currentUser!.id!);
    if (updatedPost != null) {
      final index = _feedPosts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _feedPosts[index] = updatedPost;
        notifyListeners();
      }
    }
  }

  // Spaces & Members
  Future<void> loadSpaces() async {
    _spaces = await _db.getSpaces();
    notifyListeners();
  }

  // Chat/Messages Loading
  Future<void> loadSpaceMessages(int spaceId) async {
    _activeChatMessages = await _db.getSpaceMessages(spaceId);
    notifyListeners();
  }

  Future<void> loadEventMessages(int eventId) async {
    _activeChatMessages = await _db.getEventMessages(eventId);
    notifyListeners();
  }

  Future<void> loadDirectMessages(int otherUserId) async {
    if (_currentUser == null) return;
    _activeChatMessages = await _db.getDirectMessages(_currentUser!.id!, otherUserId);
    notifyListeners();
  }

  Future<void> sendChatMessage({int? receiverId, int? eventId, int? spaceId, required String content}) async {
    if (_currentUser == null) return;

    final msg = MessageModel(
      senderId: _currentUser!.id!,
      receiverId: receiverId,
      eventId: eventId,
      spaceId: spaceId,
      content: content,
      timestamp: DateTime.now(),
    );

    await _db.insertMessage(msg);

    // Reload the active chat view
    if (spaceId != null) {
      await loadSpaceMessages(spaceId);
    } else if (eventId != null) {
      await loadEventMessages(eventId);
    } else if (receiverId != null) {
      await loadDirectMessages(receiverId);
    }
  }

  // Notifications
  Future<void> loadNotifications() async {
    if (_currentUser == null) return;
    _notifications = await _db.getNotifications(_currentUser!.id!);
    _unreadNotificationsCount = await _db.getUnreadNotificationsCount(_currentUser!.id!);
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    if (_currentUser == null) return;
    await _db.markNotificationsAsRead(_currentUser!.id!);
    await loadNotifications();
  }

  // Profile Following & Connections
  Future<void> loadMutuals() async {
    if (_currentUser == null) return;
    _mutuals = await _db.getMutuals(_currentUser!.id!);
    notifyListeners();
  }

  Future<Map<String, int>> getUserStats(int userId) async {
    return await _db.getUserStats(userId);
  }

  Future<List<PostModel>> getUserPosts(int userId) async {
    if (_currentUser == null) return [];
    return await _db.getUserPosts(userId, _currentUser!.id!);
  }

  Future<List<PostModel>> getUserRsvps(int userId) async {
    if (_currentUser == null) return [];
    return await _db.getUserRsvps(userId, _currentUser!.id!);
  }

  Future<bool> getIsFollowing(int targetUserId) async {
    if (_currentUser == null) return false;
    return await _db.isFollowing(_currentUser!.id!, targetUserId);
  }

  Future<void> toggleFollowUser(int targetUserId) async {
    if (_currentUser == null) return;
    await _db.toggleFollow(_currentUser!.id!, targetUserId);
    await loadMutuals(); // Reload mutuals in case a DM becomes available
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    required List<String> skills,
    required String goal,
    required String github,
    required String linkedin,
    required String portfolio,
    int? avatarIndex,
  }) async {
    if (_currentUser == null) return;

    final updated = _currentUser!.copyWith(
      name: name,
      bio: bio,
      skills: skills,
      goal: goal,
      github: github,
      linkedin: linkedin,
      portfolio: portfolio,
      avatarIndex: avatarIndex ?? _currentUser!.avatarIndex,
    );

    await _db.updateUserProfile(updated);
    _currentUser = updated;
    await reloadAllData();
    notifyListeners();
  }
}
