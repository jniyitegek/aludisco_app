import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../data/models/user_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/space_model.dart';
import '../../data/database_helper.dart';
import '../home/home_feed_screen.dart';
import '../profile/profile_screen.dart';
import '../spaces/space_detail_screen.dart';
import '../chat/chat_room_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'all'; // 'all', 'people', 'opportunities', 'spaces'
  
  List<UserModel> _peopleResults = [];
  List<PostModel> _opportunityResults = [];
  List<SpaceModel> _spaceResults = [];
  List<UserModel> _recommendations = [];
  List<UserModel> _topFollowed = [];
  Map<int, int> _topFollowedFollowerCounts = {};
  Map<int, bool> _topFollowedIsFollowing = {};
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadDiscoveryData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDiscoveryData() async {
    final state = Provider.of<AppState>(context, listen: false);
    final user = state.currentUser;
    if (user == null) return;

    final db = await DatabaseHelper.instance.database;
    
    // 1. Load recommendations based on cohort/major/graduation year
    final recResults = await db.query(
      'users',
      where: 'id != ? AND (major = ? OR graduation_year = ? OR role = ?)',
      whereArgs: [user.id!, user.major ?? '', user.graduationYear ?? 0, 'alumni'],
      limit: 5,
    );

    // 2. Load top followed profiles (excluding current user)
    final topFollowedResults = await db.rawQuery('''
      SELECT u.*, COUNT(f.follower_id) as follower_count
      FROM users u
      LEFT JOIN follows f ON u.id = f.following_id
      WHERE u.id != ?
      GROUP BY u.id
      ORDER BY follower_count DESC, u.name ASC
      LIMIT 5
    ''', [user.id!]);

    final List<UserModel> topFollowedList = [];
    final Map<int, int> followerCounts = {};
    final Map<int, bool> isFollowingMap = {};

    for (var row in topFollowedResults) {
      final u = UserModel.fromMap(row);
      topFollowedList.add(u);
      followerCounts[u.id!] = row['follower_count'] as int;
      isFollowingMap[u.id!] = await state.getIsFollowing(u.id!);
    }

    // 3. Ensure mutuals are loaded in state
    await state.loadMutuals();

    if (mounted) {
      setState(() {
        _recommendations = recResults.map((m) => UserModel.fromMap(m)).toList();
        _topFollowed = topFollowedList;
        _topFollowedFollowerCounts = followerCounts;
        _topFollowedIsFollowing = isFollowingMap;
      });
    }
  }

  Future<void> _toggleFollow(int targetUserId) async {
    final state = Provider.of<AppState>(context, listen: false);
    await state.toggleFollowUser(targetUserId);
    await _loadDiscoveryData();
  }

  Future<void> _executeSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _peopleResults = [];
        _opportunityResults = [];
        _spaceResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final state = Provider.of<AppState>(context, listen: false);
    final currentUserId = state.currentUser?.id ?? 0;
    
    final db = await DatabaseHelper.instance.database;
    final pattern = '%${query.trim().toLowerCase()}%';

    // 1. Search People
    final peopleMaps = await db.rawQuery('''
      SELECT * FROM users 
      WHERE (name LIKE ? OR skills LIKE ? OR bio LIKE ? OR major LIKE ?)
        AND id != ?
    ''', [pattern, pattern, pattern, pattern, currentUserId]);
    final people = peopleMaps.map((m) => UserModel.fromMap(m)).toList();

    // 2. Search Opportunities
    final oppPosts = await DatabaseHelper.instance.getFeedPosts(
      currentUserId,
      search: query,
    );
    final opps = oppPosts.where((p) => p.type == 'opportunity').toList();

    // 3. Search Spaces
    final spaceMaps = await db.rawQuery('''
      SELECT * FROM spaces 
      WHERE name LIKE ? OR description LIKE ?
    ''', [pattern, pattern]);
    final spaces = spaceMaps.map((m) => SpaceModel.fromMap(m)).toList();

    setState(() {
      _peopleResults = people;
      _opportunityResults = opps;
      _spaceResults = spaces;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search people, skills, hackathons...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 15),
          ),
          style: const TextStyle(fontSize: 16),
          onChanged: (val) => _executeSearch(val),
        ),
        actions: [
          if (hasQuery)
            IconButton(
              icon: const Icon(Icons.clear, color: AppTheme.aluNavy),
              onPressed: () {
                _searchController.clear();
                _executeSearch('');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          _buildFilterChips(),
          
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: AppTheme.aluNavy))
                : hasQuery
                    ? _buildSearchResults()
                    : _buildDefaultRecommendations(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          _buildChip('All Results', 'all'),
          const SizedBox(width: 8),
          _buildChip('People', 'people'),
          const SizedBox(width: 8),
          _buildChip('Opportunities', 'opportunities'),
          const SizedBox(width: 8),
          _buildChip('Spaces', 'spaces'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String type) {
    final isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _filterType = type);
        }
      },
      selectedColor: AppTheme.aluNavy,
      backgroundColor: AppTheme.background,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    );
  }

  Widget _buildDefaultRecommendations() {
    final state = Provider.of<AppState>(context);
    final mutualsList = state.mutuals;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: My Connections
          const Text(
            'My Connections',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.aluNavy),
          ),
          const SizedBox(height: 4),
          const Text(
            'Profiles you follow mutually. Tap message to chat directly.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (mutualsList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Column(
                children: [
                  Icon(Icons.people_outline, color: AppTheme.textLight, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'No mutual connections yet',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Follow other students & alumni. When they follow you back, you\'ll connect!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppTheme.textLight),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: mutualsList.length,
                itemBuilder: (context, index) {
                  final connection = mutualsList[index];
                  return _buildConnectionCard(connection);
                },
              ),
            ),
          
          const SizedBox(height: 24),

          // Section 2: Top Followed Profiles
          const Text(
            'Top Followed Profiles',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.aluNavy),
          ),
          const SizedBox(height: 4),
          const Text(
            'Highly followed builders and creators in the ALU network.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (_topFollowed.isEmpty)
            const Center(child: Text('Loading top followed...', style: TextStyle(color: AppTheme.textLight)))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topFollowed.length,
              itemBuilder: (context, index) {
                final user = _topFollowed[index];
                return _buildTopFollowedRow(user);
              },
            ),

          const SizedBox(height: 24),

          // Section 3: People You Might Know
          const Text(
            'People you might know',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.aluNavy),
          ),
          const SizedBox(height: 4),
          const Text(
            'Based on your major, track, or cohort year.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (_recommendations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('No recommendations found at the moment.', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
            )
          else
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  final rec = _recommendations[index];
                  return _buildRecommendedUserCard(rec);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(UserModel connection) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => _navigateToProfile(connection.id!),
            child: Column(
              children: [
                AppTheme.buildAvatar(connection.name, connection.avatarIndex, radius: 20),
                const SizedBox(height: 8),
                Text(
                  connection.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                Text(
                  connection.role == 'student' ? 'Student' : 'Alumni',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: AppTheme.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 26,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomScreen(
                      receiverId: connection.id!,
                      chatTitle: connection.name,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 10, color: Colors.white),
              label: const Text('Chat', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.aluNavy,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFollowedRow(UserModel user) {
    final followerCount = _topFollowedFollowerCounts[user.id!] ?? 0;
    final isFollowing = _topFollowedIsFollowing[user.id!] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: InkWell(
          onTap: () => _navigateToProfile(user.id!),
          child: AppTheme.buildAvatar(user.name, user.avatarIndex),
        ),
        title: InkWell(
          onTap: () => _navigateToProfile(user.id!),
          child: Row(
            children: [
              Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: user.role == 'student' ? AppTheme.aluNavy.withOpacity(0.08) : AppTheme.aluRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  user.role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: user.role == 'student' ? AppTheme.aluNavy : AppTheme.aluRed,
                  ),
                ),
              ),
            ],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.bio,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people_alt_outlined, size: 12, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  '$followerCount ${followerCount == 1 ? 'follower' : 'followers'}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        trailing: SizedBox(
          width: 86,
          height: 30,
          child: ElevatedButton(
            onPressed: () => _toggleFollow(user.id!),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? AppTheme.background : AppTheme.aluRed,
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isFollowing ? AppTheme.borderLight : Colors.transparent,
                ),
              ),
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: TextStyle(
                color: isFollowing ? AppTheme.textSecondary : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedUserCard(UserModel rec) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppTheme.buildAvatar(rec.name, rec.avatarIndex, radius: 24),
          const SizedBox(height: 8),
          Text(
            rec.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            rec.role == 'student' ? 'Year ${rec.currentYear} Student' : 'Alumni (${rec.graduationYear})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 28,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _navigateToProfile(rec.id!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.aluNavy,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final List<Widget> listItems = [];

    // Render People
    if (_filterType == 'all' || _filterType == 'people') {
      if (_peopleResults.isNotEmpty) {
        listItems.add(_buildSectionHeader('People'));
        listItems.addAll(_peopleResults.map((p) => _buildPeopleRow(p)));
      }
    }

    // Render Opportunities
    if (_filterType == 'all' || _filterType == 'opportunities') {
      if (_opportunityResults.isNotEmpty) {
        listItems.add(_buildSectionHeader('Opportunities'));
        listItems.addAll(_opportunityResults.map((o) => FeedCard(post: o)));
      }
    }

    // Render Spaces
    if (_filterType == 'all' || _filterType == 'spaces') {
      if (_spaceResults.isNotEmpty) {
        listItems.add(_buildSectionHeader('Spaces'));
        listItems.addAll(_spaceResults.map((s) => _buildSpaceRow(s)));
      }
    }

    if (listItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.textLight),
            SizedBox(height: 16),
            Text('No results match your search.', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            SizedBox(height: 8),
            Text('Check spelling or try other keywords.', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: listItems,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.aluRed),
      ),
    );
  }

  Widget _buildPeopleRow(UserModel p) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: AppTheme.buildAvatar(p.name, p.avatarIndex),
      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.bio, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: p.skills.take(3).map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(4)),
                child: Text(s, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
              );
            }).toList(),
          )
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textLight),
      onTap: () => _navigateToProfile(p.id!),
    );
  }

  Widget _buildSpaceRow(SpaceModel s) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppTheme.background,
        child: Icon(Icons.tag, color: AppTheme.aluNavy),
      ),
      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(s.description, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textLight),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SpaceDetailScreen(space: s)),
        );
      },
    );
  }

  void _navigateToProfile(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: ProfileScreen(userId: userId),
        ),
      ),
    );
  }
}
