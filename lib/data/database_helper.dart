import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models/user_model.dart';
import 'models/post_model.dart';
import 'models/comment_model.dart';
import 'models/space_model.dart';
import 'models/message_model.dart';
import 'models/notification_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('aludisco.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Delete existing database for clean seeding if desired:
    // await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE users ADD COLUMN is_logged_in INTEGER DEFAULT 0');
          } catch (e) {
            // Column may already exist in some environments, safe to ignore
          }
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const intNullable = 'INTEGER';

    // Users Table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        email TEXT UNIQUE NOT NULL,
        name $textType,
        role $textType,
        bio $textType,
        skills $textType,
        goal $textType,
        github $textType,
        linkedin $textType,
        portfolio $textType,
        avatar_index $intType,
        graduation_year $intNullable,
        cohort $textNullable,
        current_year $intNullable,
        major $textNullable,
        is_verified $intType,
        is_logged_in INTEGER DEFAULT 0
      )
    ''');

    // Follows Table
    await db.execute('''
      CREATE TABLE follows (
        follower_id $intType,
        following_id $intType,
        PRIMARY KEY (follower_id, following_id),
        FOREIGN KEY (follower_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (following_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Spaces Table
    await db.execute('''
      CREATE TABLE spaces (
        id $idType,
        name TEXT UNIQUE NOT NULL,
        description $textType,
        icon $textType
      )
    ''');

    // Space Members
    await db.execute('''
      CREATE TABLE space_members (
        space_id $intType,
        user_id $intType,
        PRIMARY KEY (space_id, user_id),
        FOREIGN KEY (space_id) REFERENCES spaces (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Posts Table
    await db.execute('''
      CREATE TABLE posts (
        id $idType,
        author_id $intType,
        title $textType,
        description $textType,
        type $textType,
        category $textType,
        image_path $textNullable,
        timestamp $textType,
        space_id $intNullable,
        pinned $intType,
        event_date $textNullable,
        event_location $textNullable,
        registration_link $textNullable,
        in_app_rsvp $intType,
        target_audience $textType,
        FOREIGN KEY (author_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (space_id) REFERENCES spaces (id) ON DELETE SET NULL
      )
    ''');

    // Saved Posts Table
    await db.execute('''
      CREATE TABLE saved_posts (
        user_id $intType,
        post_id $intType,
        PRIMARY KEY (user_id, post_id),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE
      )
    ''');

    // Reactions Table
    await db.execute('''
      CREATE TABLE reactions (
        post_id $intType,
        user_id $intType,
        type $textType,
        PRIMARY KEY (post_id, user_id),
        FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Comments Table
    await db.execute('''
      CREATE TABLE comments (
        id $idType,
        post_id $intType,
        author_id $intType,
        content $textType,
        parent_id $intNullable,
        timestamp $textType,
        FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE,
        FOREIGN KEY (author_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (parent_id) REFERENCES comments (id) ON DELETE CASCADE
      )
    ''');

    // RSVPs Table
    await db.execute('''
      CREATE TABLE rsvps (
        post_id $intType,
        user_id $intType,
        status $textType,
        timestamp $textType,
        PRIMARY KEY (post_id, user_id),
        FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Messages Table
    await db.execute('''
      CREATE TABLE messages (
        id $idType,
        sender_id $intType,
        receiver_id $intNullable,
        event_id $intNullable,
        space_id $intNullable,
        content $textType,
        timestamp $textType,
        FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (event_id) REFERENCES posts (id) ON DELETE CASCADE,
        FOREIGN KEY (space_id) REFERENCES spaces (id) ON DELETE CASCADE
      )
    ''');

    // Notifications Table
    await db.execute('''
      CREATE TABLE notifications (
        id $idType,
        user_id $intType,
        sender_id $intType,
        type $textType,
        post_id $intNullable,
        message $textType,
        is_read $intType,
        timestamp $textType,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Seed Initial Data
    await _seedInitialData(db);
  }

  Future _seedInitialData(Database db) async {
    // 1. Seed Users (1: Kevin Nyawakira, 2: ALU Tech Club, 3: Divine Kuzo, 4: Paul Udongo, 5: Jimmy Kamanzi)
    await db.insert('users', {
      'id': 1,
      'email': 'knyawakira@alueducation.com',
      'name': 'Kevin Nyawakira',
      'role': 'alumni',
      'bio': 'Software Engineer @ Google. Class of 2024. Passionate about GSoC, Flutter, and mentoring students.',
      'skills': 'Python,React,Flutter,System Design,Open Source',
      'goal': 'Mentor students and build open-source tools',
      'github': 'github.com/knyawakira',
      'linkedin': 'linkedin.com/in/knyawakira',
      'portfolio': 'knyawakira.dev',
      'avatar_index': 1,
      'graduation_year': 2024,
      'cohort': 'Cohort 4',
      'is_verified': 1
    });

    await db.insert('users', {
      'id': 2,
      'email': 'techclub@alustudent.com',
      'name': 'ALU Tech Club',
      'role': 'organizer',
      'bio': 'Official student-led community for technology and builders at ALU. Organizers of hackathons & labs.',
      'skills': 'Hackathons,Coding,UI/UX,Leadership,Workshops',
      'goal': 'Empowering students to build world-class tech products',
      'github': 'github.com/alutechclub',
      'linkedin': '',
      'portfolio': 'alutechclub.com',
      'avatar_index': 2,
      'is_verified': 1
    });

    await db.insert('users', {
      'id': 3,
      'email': 'dkuzo@alustudent.com',
      'name': 'Divine Kuzo',
      'role': 'student',
      'bio': 'Year 3 Software Engineering. Aspiring PM & Flutter dev. Love Figma and prototyping ideas.',
      'skills': 'Product Design,Figma,Flutter,JavaScript',
      'goal': 'Looking for product design / frontend internships in fintech',
      'github': 'github.com/dkuzo',
      'linkedin': 'linkedin.com/in/dkuzo',
      'portfolio': 'dkuzo.design',
      'avatar_index': 3,
      'current_year': 3,
      'major': 'Software Engineering',
      'is_verified': 1
    });

    await db.insert('users', {
      'id': 4,
      'email': 'pudongo@alustudent.com',
      'name': 'Paul Udongo',
      'role': 'student',
      'bio': 'Year 2 Global Challenges. Startup builder and pitching lead. Let\'s build the next big thing!',
      'skills': 'Pitching,Business Development,Leadership,Strategy',
      'goal': 'Find a tech co-founder for a sustainable climate startup',
      'github': '',
      'linkedin': 'linkedin.com/in/pudongo',
      'portfolio': '',
      'avatar_index': 4,
      'current_year': 2,
      'major': 'Global Challenges',
      'is_verified': 1
    });

    await db.insert('users', {
      'id': 5,
      'email': 'jkamanzi@alueducation.com',
      'name': 'Jimmy Kamanzi',
      'role': 'alumni',
      'bio': 'Product Manager @ Flutterwave. Class of 2023. Happy to share resume advice & help with PM interviews.',
      'skills': 'Product Management,Agile,SQL,Data Analytics',
      'goal': 'Mentoring & recruiting students for fintech internships',
      'github': '',
      'linkedin': 'linkedin.com/in/jkamanzi',
      'portfolio': '',
      'avatar_index': 5,
      'graduation_year': 2023,
      'cohort': 'Cohort 3',
      'is_verified': 1
    });

    await db.insert('users', {
      'id': 6,
      'email': 'kepha@alustudent.com',
      'name': 'Kepha Okoth',
      'role': 'student',
      'bio': 'Year 3 Software Engineering. Aspiring PM & Flutter dev. Love Figma and prototyping ideas.',
      'skills': 'Product Design,Figma,Flutter,JavaScript',
      'goal': 'Looking for product design / frontend internships in fintech',
      'github': 'github.com/dkuzo',
      'linkedin': 'linkedin.com/in/dkuzo',
      'portfolio': 'dkuzo.design',
      'avatar_index': 3,
      'current_year': 3,
      'major': 'Software Engineering',
      'is_verified': 1
    });

    // 2. Seed Follows (Mutual: 1 <-> 3, 3 <-> 4)
    await db.insert('follows', {'follower_id': 1, 'following_id': 3});
    await db.insert('follows', {'follower_id': 3, 'following_id': 1});
    await db.insert('follows', {'follower_id': 3, 'following_id': 4});
    await db.insert('follows', {'follower_id': 4, 'following_id': 3});
    await db.insert('follows', {'follower_id': 1, 'following_id': 2}); // Kevin follows Tech Club
    await db.insert('follows', {'follower_id': 3, 'following_id': 2}); // Divine follows Tech Club

    // 3. Seed Spaces
    await db.insert('spaces', {
      'id': 1,
      'name': '#startups',
      'description': 'Entrepreneurship, pitches, collaborations, and brainstorming new ideas.',
      'icon': 'rocket_launch'
    });
    await db.insert('spaces', {
      'id': 2,
      'name': '#career',
      'description': 'Job postings, internship opportunities, resume reviews, and career advice.',
      'icon': 'work'
    });
    await db.insert('spaces', {
      'id': 3,
      'name': '#tech-builds',
      'description': 'Showcasing projects, sharing code snippets, tech stacks, and demo videos.',
      'icon': 'code'
    });
    await db.insert('spaces', {
      'id': 4,
      'name': '#campus-life',
      'description': 'General announcements, events, and student life updates.',
      'icon': 'school'
    });
    await db.insert('spaces', {
      'id': 5,
      'name': '#alumni-connect',
      'description': 'Alumni-only space for mentorship offers, network building, and job referrals.',
      'icon': 'people'
    });

    // Join spaces automatically for seeded users
    for (int i = 1; i <= 5; i++) {
      for (int space = 1; space <= 4; space++) {
        await db.insert('space_members', {'space_id': space, 'user_id': i});
      }
      if (i == 1 || i == 5) {
        // Alumni join #alumni-connect
        await db.insert('space_members', {'space_id': 5, 'user_id': i});
      }
    }

    // 4. Seed Posts
    // Post 1: Kevin Nyawakira Achievement (matches Image 2 first card)
    await db.insert('posts', {
      'id': 1,
      'author_id': 1,
      'title': 'Accepted to Google Summer of Code!',
      'description': 'Thrilled to announce that I\'ve been accepted to Google Summer of Code! Can\'t wait to grow publicly and share my journey with the ALU tech community. 🚀',
      'type': 'achievement',
      'category': 'Career Win',
      'image_path': 'assets/images/gsoc_mac.jpg', // Placeholder string
      'timestamp': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      'space_id': 3, // #tech-builds
      'pinned': 1,
      'in_app_rsvp': 0,
      'target_audience': ''
    });

    // Post 2: ALU Tech Club Opportunity (matches Image 2 second card)
    await db.insert('posts', {
      'id': 2,
      'author_id': 2,
      'title': 'ALU Tech Hackathon 2024',
      'description': 'Join us for 48 hours of building, learning, and networking. All skill levels are welcome. Let\'s solve real-world problems and prototype solutions with real impact!',
      'type': 'opportunity',
      'category': 'Hackathon',
      'image_path': null,
      'timestamp': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      'space_id': 4, // #campus-life
      'pinned': 0,
      'event_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(), // Tomorrow (less than 48 hours, reminder badge triggers!)
      'event_location': 'ALU Innovation Hub (Hybrid)',
      'registration_link': '',
      'in_app_rsvp': 1,
      'target_audience': 'Software Engineering,Product Design,Global Challenges'
    });

    // Post 3: Divine Kuzo Project Launch
    await db.insert('posts', {
      'id': 3,
      'author_id': 3,
      'title': 'Launched ALUDISCO Flutter UI',
      'description': 'Finally got the onboarding and feed components working with a local SQLite database! Clean animations and premium styling inside and out. Feedback welcome!',
      'type': 'achievement',
      'category': 'Project Launch',
      'image_path': null,
      'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'space_id': 3, // #tech-builds
      'pinned': 0,
      'in_app_rsvp': 0,
      'target_audience': ''
    });

    // Post 4: Jimmy Kamanzi PM Internship Opportunity
    await db.insert('posts', {
      'id': 4,
      'author_id': 5,
      'title': 'Fintech PM Intern @ Flutterwave',
      'description': 'Looking for a smart student or recent grad to join my team as a Product Analyst Intern. Excellent entry-level path into fintech PM. Reach out with your resume!',
      'type': 'opportunity',
      'category': 'Internship',
      'image_path': null,
      'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'space_id': 2, // #career
      'pinned': 0,
      'event_date': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
      'event_location': 'Remote (Nigeria/Kenya/Rwanda)',
      'registration_link': 'https://careers.flutterwave.com',
      'in_app_rsvp': 0, // Out of app registration
      'target_audience': 'Product Management,Business,Software Engineering'
    });

    // 5. Seed Reactions on Kevin Nyawakira's GSoC post (Post 1)
    // 👏 Respect (12), 🔥 Impressive (8), 🚀 Inspired (5)
    // We can simulate counts by inserting exact rows.
    // Insert Respect reactions
    for (int i = 1; i <= 12; i++) {
      await db.insert('reactions', {'post_id': 1, 'user_id': 100 + i, 'type': 'respect'});
    }
    // Insert Impressive reactions
    for (int i = 1; i <= 8; i++) {
      await db.insert('reactions', {'post_id': 1, 'user_id': 200 + i, 'type': 'impressive'});
    }
    // Insert Inspired reactions
    for (int i = 1; i <= 5; i++) {
      await db.insert('reactions', {'post_id': 1, 'user_id': 300 + i, 'type': 'inspired'});
    }
    // Make Divine (user 3) react to Kevin's post (type: inspired)
    await db.delete('reactions', where: 'post_id = ? AND user_id = ?', whereArgs: [1, 3]);
    await db.insert('reactions', {'post_id': 1, 'user_id': 3, 'type': 'inspired'});

    // 6. Seed Comments on Post 1
    await db.insert('comments', {
      'id': 1,
      'post_id': 1,
      'author_id': 3, // Divine
      'content': 'This is massive Kevin! Super proud of you! GSoC is a huge milestone. 👏',
      'parent_id': null,
      'timestamp': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String()
    });

    await db.insert('comments', {
      'id': 2,
      'post_id': 1,
      'author_id': 1, // Kevin Nyawakira (reply to Divine)
      'content': 'Thank you Divine! Happy to review your proposals or help out when applications open next season!',
      'parent_id': 1,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()
    });

    await db.insert('comments', {
      'id': 3,
      'post_id': 1,
      'author_id': 4, // Paul Udongo
      'content': 'Super inspiring! Tech stacks at GSoC are great.',
      'parent_id': null,
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String()
    });

    // 7. Seed RSVPs for ALU Tech Hackathon (Post 2)
    // Divine (user 3) is RSVP'd (upcoming)
    await db.insert('rsvps', {
      'post_id': 2,
      'user_id': 3,
      'status': 'upcoming',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String()
    });
    // Paul (user 4) is RSVP'd (upcoming)
    await db.insert('rsvps', {
      'post_id': 2,
      'user_id': 4,
      'status': 'upcoming',
      'timestamp': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String()
    });

    // Seed additional attendees to boost count
    for (int i = 1; i <= 24; i++) {
      await db.insert('rsvps', {
        'post_id': 2,
        'user_id': 400 + i,
        'status': 'upcoming',
        'timestamp': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String()
      });
    }

    // 8. Seed Chat Messages
    // Event Chat messages for Post 2 (Hackathon)
    await db.insert('messages', {
      'sender_id': 2, // Tech Club
      'event_id': 2,
      'content': 'Hey hackers! Welcome to the ALU Tech Hackathon 2024 event chat. Feel free to use this space to form teams, brainstorm, or ask questions.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String()
    });
    await db.insert('messages', {
      'sender_id': 3, // Divine
      'event_id': 2,
      'content': 'Hi guys! Looking for teammates. I can handle Product Design, Figma, and Flutter implementation.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String()
    });
    await db.insert('messages', {
      'sender_id': 4, // Paul
      'event_id': 2,
      'content': 'Hey Divine! I am doing Global Challenges, good at pitching and project outlines. Let\'s partner up! We need a backend developer.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String()
    });

    // Space Chat message for #startups (Space 1)
    await db.insert('messages', {
      'sender_id': 4, // Paul
      'space_id': 1,
      'content': 'Is anyone attending the ALU Pitch Deck workshop next Tuesday? Looking to grab feedback on a pitch.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 10)).toIso8601String()
    });

    // DM Messages between mutual follows Kevin (1) and Divine (3)
    await db.insert('messages', {
      'sender_id': 3, // Divine
      'receiver_id': 1, // Kevin
      'content': 'Hi Kevin! I saw your post about GSoC. Huge congratulations again! I was wondering if I could ask a quick question about choosing an organization?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 24)).toIso8601String()
    });
    await db.insert('messages', {
      'sender_id': 1, // Kevin
      'receiver_id': 3, // Divine
      'content': 'Hey Divine, thanks! Absolutely, fire away. The trick is to look for active repositories early and start contributing to beginner-friendly bugs.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 23)).toIso8601String()
    });
    await db.insert('messages', {
      'sender_id': 3, // Divine
      'receiver_id': 1, // Kevin
      'content': 'That makes sense. I have standard skills in Flutter and python, is it better to stick to Dart-based orgs or widen the scope?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 22)).toIso8601String()
    });

    // 9. Seed Notifications for Divine (3)
    await db.insert('notifications', {
      'user_id': 3,
      'sender_id': 1, // Kevin Nyawakira
      'type': 'reply',
      'post_id': 1,
      'message': 'Kevin Nyawakira replied to your comment: "Thank you Divine! Happy to review..."',
      'is_read': 0,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()
    });
    await db.insert('notifications', {
      'user_id': 3,
      'sender_id': 4, // Paul
      'type': 'follow',
      'message': 'Paul Udongo started following you.',
      'is_read': 1,
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String()
    });
  }

  Future<void> setLoggedInUser(int userId) async {
    final db = await instance.database;
    await db.update('users', {'is_logged_in': 0});
    await db.update('users', {'is_logged_in': 1}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<UserModel?> getLoggedInUser() async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'is_logged_in = 1',
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> clearLoggedInUser() async {
    final db = await instance.database;
    await db.update('users', {'is_logged_in': 0});
  }

  // --- REPOSITORY INTERFACES ---

  // Auth & Profile
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<UserModel> registerUser(UserModel user) async {
    final db = await instance.database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<int> updateUserProfile(UserModel user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Follow Actions
  Future<bool> isFollowing(int followerId, int followingId) async {
    final db = await instance.database;
    final result = await db.query(
      'follows',
      where: 'follower_id = ? AND following_id = ?',
      whereArgs: [followerId, followingId],
    );
    return result.isNotEmpty;
  }

  Future<void> toggleFollow(int followerId, int followingId) async {
    final db = await instance.database;
    final follows = await isFollowing(followerId, followingId);
    if (follows) {
      await db.delete(
        'follows',
        where: 'follower_id = ? AND following_id = ?',
        whereArgs: [followerId, followingId],
      );
    } else {
      await db.insert('follows', {
        'follower_id': followerId,
        'following_id': followingId,
      });
      // Trigger a notification
      final follower = await getUserById(followerId);
      if (follower != null) {
        await insertNotification(NotificationModel(
          userId: followingId,
          senderId: followerId,
          type: 'follow',
          message: '${follower.name} started following you.',
          isRead: false,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  Future<List<UserModel>> getFollowers(int userId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT users.* FROM users
      INNER JOIN follows ON users.id = follows.follower_id
      WHERE follows.following_id = ?
    ''', [userId]);
    return maps.map((m) => UserModel.fromMap(m)).toList();
  }

  Future<List<UserModel>> getFollowing(int userId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT users.* FROM users
      INNER JOIN follows ON users.id = follows.following_id
      WHERE follows.follower_id = ?
    ''', [userId]);
    return maps.map((m) => UserModel.fromMap(m)).toList();
  }

  Future<List<UserModel>> getMutuals(int userId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT u.* FROM users u
      WHERE u.id IN (
        SELECT f1.following_id FROM follows f1
        INNER JOIN follows f2 ON f1.following_id = f2.follower_id AND f1.follower_id = f2.following_id
        WHERE f1.follower_id = ?
      )
    ''', [userId]);
    return maps.map((m) => UserModel.fromMap(m)).toList();
  }

  // Spaces
  Future<List<SpaceModel>> getSpaces() async {
    final db = await instance.database;
    final maps = await db.query('spaces');
    return maps.map((m) => SpaceModel.fromMap(m)).toList();
  }

  // Posts Feed & Interactions
  Future<List<PostModel>> getFeedPosts(int currentUserId, {String? tab, int? spaceId, String? search}) async {
    final db = await instance.database;
    
    // We construct a query that fetches the post details plus the author info.
    // Also we will join reactions & comment count inside Dart, or via sub-queries.
    String whereClause = '1 = 1';
    List<dynamic> whereArgs = [];

    if (spaceId != null) {
      whereClause += ' AND posts.space_id = ?';
      whereArgs.add(spaceId);
    }

    if (search != null && search.isNotEmpty) {
      whereClause += ' AND (posts.title LIKE ? OR posts.description LIKE ? OR users.name LIKE ? OR users.skills LIKE ?)';
      final pattern = '%$search%';
      whereArgs.addAll([pattern, pattern, pattern, pattern]);
    }

    // Role-specific/algorithmic matching logic for "For You"
    String orderBy = 'posts.timestamp DESC';
    if (tab == 'for_you') {
      // Simple algorithm:
      // Match posts where the target_audience tags or skills overlap with current user's skills,
      // or prioritize posts with more reactions, or posts created by mutuals.
      // For this SQLite version, we can order by matching tags, then timestamp.
      final currentUser = await getUserById(currentUserId);
      if (currentUser != null && currentUser.skills.isNotEmpty) {
        String skillsMatchScore = '0';
        for (var skill in currentUser.skills) {
          skillsMatchScore += ' + (CASE WHEN posts.target_audience LIKE \'%$skill%\' OR posts.description LIKE \'%$skill%\' THEN 3 ELSE 0 END)';
        }
        orderBy = '($skillsMatchScore) DESC, posts.timestamp DESC';
      }
    }

    final query = '''
      SELECT posts.*, 
             users.name AS author_name, 
             users.role AS author_role, 
             users.avatar_index AS author_avatar_index,
             users.is_verified AS author_is_verified,
             CASE 
               WHEN users.role = 'student' THEN 'Class of ' || users.current_year
               WHEN users.role = 'alumni' THEN 'Class of ' || users.graduation_year
               ELSE 'Organizer'
             END AS author_subtitle
      FROM posts
      INNER JOIN users ON posts.author_id = users.id
      WHERE $whereClause
      ORDER BY $orderBy
    ''';

    final maps = await db.rawQuery(query, whereArgs);
    List<PostModel> posts = [];

    for (var map in maps) {
      final postId = map['id'] as int;

      // 1. Get Reaction Counts
      final respectCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reactions WHERE post_id = ? AND type = "respect"', [postId])) ?? 0;
      final impressiveCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reactions WHERE post_id = ? AND type = "impressive"', [postId])) ?? 0;
      final inspiredCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reactions WHERE post_id = ? AND type = "inspired"', [postId])) ?? 0;
      
      final reactionCounts = {
        'respect': respectCount,
        'impressive': impressiveCount,
        'inspired': inspiredCount,
      };

      // 2. Get current user reaction
      final userReactMap = await db.query('reactions', columns: ['type'], where: 'post_id = ? AND user_id = ?', whereArgs: [postId, currentUserId]);
      final currentUserReaction = userReactMap.isNotEmpty ? userReactMap.first['type'] as String : null;

      // 3. Get Comment Count
      final commentCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM comments WHERE post_id = ?', [postId])) ?? 0;

      // 4. Get Is Saved
      final savedMap = await db.query('saved_posts', where: 'post_id = ? AND user_id = ?', whereArgs: [postId, currentUserId]);
      final isSaved = savedMap.isNotEmpty;

      // 5. Get RSVPs count (attendee count)
      final attendeeCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM rsvps WHERE post_id = ? AND status = "upcoming"', [postId])) ?? 0;

      // 6. Current user RSVP status
      final rsvpMap = await db.query('rsvps', columns: ['status'], where: 'post_id = ? AND user_id = ?', whereArgs: [postId, currentUserId]);
      final userRsvpStatus = rsvpMap.isNotEmpty ? rsvpMap.first['status'] as String : null;

      posts.add(PostModel.fromMap(
        map,
        reactions: reactionCounts,
        currentUserReaction: currentUserReaction,
        comments: commentCount,
        saved: isSaved,
        attendees: attendeeCount,
        rsvpStatus: userRsvpStatus,
      ));
    }

    return posts;
  }

  Future<PostModel?> getPostDetails(int postId, int currentUserId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT posts.*, 
             users.name AS author_name, 
             users.role AS author_role, 
             users.avatar_index AS author_avatar_index,
             users.is_verified AS author_is_verified,
             CASE 
               WHEN users.role = 'student' THEN 'Class of ' || users.current_year
               WHEN users.role = 'alumni' THEN 'Class of ' || users.graduation_year
               ELSE 'Organizer'
             END AS author_subtitle
      FROM posts
      INNER JOIN users ON posts.author_id = users.id
      WHERE posts.id = ?
    ''', [postId]);

    if (maps.isEmpty) return null;

    final map = maps.first;

    // Reaction counts
    final respectCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reactions WHERE post_id = ? AND type = "respect"', [postId])) ?? 0;
    final impressiveCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reactions WHERE post_id = ? AND type = "impressive"', [postId])) ?? 0;
    final inspiredCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reactions WHERE post_id = ? AND type = "inspired"', [postId])) ?? 0;

    final reactionCounts = {
      'respect': respectCount,
      'impressive': impressiveCount,
      'inspired': inspiredCount,
    };

    final userReactMap = await db.query('reactions', columns: ['type'], where: 'post_id = ? AND user_id = ?', whereArgs: [postId, currentUserId]);
    final currentUserReaction = userReactMap.isNotEmpty ? userReactMap.first['type'] as String : null;

    final commentCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM comments WHERE post_id = ?', [postId])) ?? 0;

    final savedMap = await db.query('saved_posts', where: 'post_id = ? AND user_id = ?', whereArgs: [postId, currentUserId]);
    final isSaved = savedMap.isNotEmpty;

    final attendeeCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM rsvps WHERE post_id = ? AND status = "upcoming"', [postId])) ?? 0;

    final rsvpMap = await db.query('rsvps', columns: ['status'], where: 'post_id = ? AND user_id = ?', whereArgs: [postId, currentUserId]);
    final userRsvpStatus = rsvpMap.isNotEmpty ? rsvpMap.first['status'] as String : null;

    return PostModel.fromMap(
      map,
      reactions: reactionCounts,
      currentUserReaction: currentUserReaction,
      comments: commentCount,
      saved: isSaved,
      attendees: attendeeCount,
      rsvpStatus: userRsvpStatus,
    );
  }

  Future<int> insertPost(PostModel post) async {
    final db = await instance.database;
    return await db.insert('posts', post.toMap());
  }

  Future<void> toggleSavePost(int postId, int userId) async {
    final db = await instance.database;
    final savedMap = await db.query('saved_posts', where: 'user_id = ? AND post_id = ?', whereArgs: [userId, postId]);
    if (savedMap.isNotEmpty) {
      await db.delete('saved_posts', where: 'user_id = ? AND post_id = ?', whereArgs: [userId, postId]);
    } else {
      await db.insert('saved_posts', {
        'user_id': userId,
        'post_id': postId,
      });
    }
  }

  Future<void> addReaction(int postId, int userId, String reactionType) async {
    final db = await instance.database;
    // Remove existing reaction if any
    await db.delete('reactions', where: 'post_id = ? AND user_id = ?', whereArgs: [postId, userId]);
    // Insert new
    await db.insert('reactions', {
      'post_id': postId,
      'user_id': userId,
      'type': reactionType,
    });

    // Notify post author (if not self)
    final post = await db.query('posts', columns: ['author_id'], where: 'id = ?', whereArgs: [postId]);
    if (post.isNotEmpty) {
      final authorId = post.first['author_id'] as int;
      if (authorId != userId) {
        final reactor = await getUserById(userId);
        if (reactor != null) {
          final emoji = reactionType == 'respect' ? '👏' : (reactionType == 'impressive' ? '🔥' : '🚀');
          await insertNotification(NotificationModel(
            userId: authorId,
            senderId: userId,
            type: 'reaction',
            postId: postId,
            message: '${reactor.name} reacted $emoji to your achievement.',
            isRead: false,
            timestamp: DateTime.now(),
          ));
        }
      }
    }
  }

  Future<void> removeReaction(int postId, int userId) async {
    final db = await instance.database;
    await db.delete('reactions', where: 'post_id = ? AND user_id = ?', whereArgs: [postId, userId]);
  }

  // RSVPs
  Future<void> rsvpToEvent(int postId, int userId, String status) async {
    final db = await instance.database;
    await db.delete('rsvps', where: 'post_id = ? AND user_id = ?', whereArgs: [postId, userId]);
    await db.insert('rsvps', {
      'post_id': postId,
      'user_id': userId,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Auto-join event chat: Seed a system welcome message or just add message
    // If it's upcoming, also trigger a notification reminder
  }

  Future<void> cancelRsvp(int postId, int userId) async {
    final db = await instance.database;
    await db.delete('rsvps', where: 'post_id = ? AND user_id = ?', whereArgs: [postId, userId]);
  }

  Future<List<UserModel>> getEventAttendees(int postId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT users.* FROM users
      INNER JOIN rsvps ON users.id = rsvps.user_id
      WHERE rsvps.post_id = ? AND rsvps.status = 'upcoming'
    ''', [postId]);
    return maps.map((m) => UserModel.fromMap(m)).toList();
  }

  // Comments
  Future<List<CommentModel>> getComments(int postId) async {
    final db = await instance.database;
    
    // Get all comments for this post
    final maps = await db.rawQuery('''
      SELECT comments.*, 
             users.name AS author_name, 
             users.role AS author_role, 
             users.avatar_index AS author_avatar_index,
             users.is_verified AS author_is_verified
      FROM comments
      INNER JOIN users ON comments.author_id = users.id
      WHERE comments.post_id = ?
      ORDER BY comments.timestamp ASC
    ''', [postId]);

    // Parse comments
    List<CommentModel> allComments = maps.map((m) => CommentModel.fromMap(m)).toList();
    
    // Group replies into parent comments (one-level deep)
    List<CommentModel> rootComments = [];
    Map<int, List<CommentModel>> parentToChildren = {};

    for (var comment in allComments) {
      if (comment.parentId == null) {
        rootComments.add(comment);
      } else {
        parentToChildren.putIfAbsent(comment.parentId!, () => []).add(comment);
      }
    }

    // Assign replies list to root comments
    return rootComments.map((root) {
      return root.copyWith(replies: parentToChildren[root.id] ?? []);
    }).toList();
  }

  Future<int> insertComment(CommentModel comment) async {
    final db = await instance.database;
    final id = await db.insert('comments', comment.toMap());

    // Send notifications if replying to someone
    if (comment.parentId != null) {
      final parentComment = await db.query('comments', columns: ['author_id'], where: 'id = ?', whereArgs: [comment.parentId]);
      if (parentComment.isNotEmpty) {
        final parentAuthorId = parentComment.first['author_id'] as int;
        if (parentAuthorId != comment.authorId) {
          final replier = await getUserById(comment.authorId);
          if (replier != null) {
            await insertNotification(NotificationModel(
              userId: parentAuthorId,
              senderId: comment.authorId,
              type: 'reply',
              postId: comment.postId,
              message: '${replier.name} replied to your comment: "${comment.content.substring(0, comment.content.length > 20 ? 20 : comment.content.length)}..."',
              isRead: false,
              timestamp: DateTime.now(),
            ));
          }
        }
      }
    } else {
      // Notify post author
      final post = await db.query('posts', columns: ['author_id'], where: 'id = ?', whereArgs: [comment.postId]);
      if (post.isNotEmpty) {
        final authorId = post.first['author_id'] as int;
        if (authorId != comment.authorId) {
          final replier = await getUserById(comment.authorId);
          if (replier != null) {
            await insertNotification(NotificationModel(
              userId: authorId,
              senderId: comment.authorId,
              type: 'reply',
              postId: comment.postId,
              message: '${replier.name} commented on your post.',
              isRead: false,
              timestamp: DateTime.now(),
            ));
          }
        }
      }
    }

    return id;
  }

  // Chats & Messaging
  Future<List<MessageModel>> getSpaceMessages(int spaceId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT messages.*, 
             users.name AS sender_name, 
             users.role AS sender_role, 
             users.avatar_index AS sender_avatar_index
      FROM messages
      INNER JOIN users ON messages.sender_id = users.id
      WHERE messages.space_id = ?
      ORDER BY messages.timestamp ASC
    ''', [spaceId]);
    return maps.map((m) => MessageModel.fromMap(m)).toList();
  }

  Future<List<MessageModel>> getEventMessages(int eventId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT messages.*, 
             users.name AS sender_name, 
             users.role AS sender_role, 
             users.avatar_index AS sender_avatar_index
      FROM messages
      INNER JOIN users ON messages.sender_id = users.id
      WHERE messages.event_id = ?
      ORDER BY messages.timestamp ASC
    ''', [eventId]);
    return maps.map((m) => MessageModel.fromMap(m)).toList();
  }

  Future<List<MessageModel>> getDirectMessages(int userA, int userB) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT messages.*, 
             users.name AS sender_name, 
             users.role AS sender_role, 
             users.avatar_index AS sender_avatar_index
      FROM messages
      INNER JOIN users ON messages.sender_id = users.id
      WHERE (messages.sender_id = ? AND messages.receiver_id = ?) 
         OR (messages.sender_id = ? AND messages.receiver_id = ?)
      ORDER BY messages.timestamp ASC
    ''', [userA, userB, userB, userA]);
    return maps.map((m) => MessageModel.fromMap(m)).toList();
  }

  Future<int> insertMessage(MessageModel msg) async {
    final db = await instance.database;
    return await db.insert('messages', msg.toMap());
  }

  // Notifications
  Future<List<NotificationModel>> getNotifications(int userId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT notifications.*, 
             users.name AS sender_name, 
             users.role AS sender_role, 
             users.avatar_index AS sender_avatar_index
      FROM notifications
      INNER JOIN users ON notifications.sender_id = users.id
      WHERE notifications.user_id = ?
      ORDER BY notifications.timestamp DESC
    ''', [userId]);
    return maps.map((m) => NotificationModel.fromMap(m)).toList();
  }

  Future<int> getUnreadNotificationsCount(int userId) async {
    final db = await instance.database;
    return Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    )) ?? 0;
  }

  Future<void> markNotificationsAsRead(int userId) async {
    final db = await instance.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> insertNotification(NotificationModel notif) async {
    final db = await instance.database;
    return await db.insert('notifications', notif.toMap());
  }

  // User Stats & Activity
  Future<Map<String, int>> getUserStats(int userId) async {
    final db = await instance.database;
    
    final followersCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM follows WHERE following_id = ?', [userId]
    )) ?? 0;

    final followingCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM follows WHERE follower_id = ?', [userId]
    )) ?? 0;

    final reactionsCount = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM reactions 
      INNER JOIN posts ON reactions.post_id = posts.id
      WHERE posts.author_id = ?
    ''', [userId])) ?? 0;

    return {
      'followers': followersCount,
      'following': followingCount,
      'reactions_received': reactionsCount,
    };
  }

  Future<List<PostModel>> getUserPosts(int userId, int currentUserId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT posts.*, 
             users.name AS author_name, 
             users.role AS author_role, 
             users.avatar_index AS author_avatar_index,
             users.is_verified AS author_is_verified,
             CASE 
               WHEN users.role = 'student' THEN 'Class of ' || users.current_year
               WHEN users.role = 'alumni' THEN 'Class of ' || users.graduation_year
               ELSE 'Organizer'
             END AS author_subtitle
      FROM posts
      INNER JOIN users ON posts.author_id = users.id
      WHERE posts.author_id = ?
      ORDER BY posts.pinned DESC, posts.timestamp DESC
    ''', [userId]);

    List<PostModel> posts = [];
    for (var map in maps) {
      final postId = map['id'] as int;

      // Reactions count
      final respectCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reactions WHERE post_id = ? AND type = "respect"', [postId])) ?? 0;
      final impressiveCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reactions WHERE post_id = ? AND type = "impressive"', [postId])) ?? 0;
      final inspiredCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reactions WHERE post_id = ? AND type = "inspired"', [postId])) ?? 0;

      final reactionCounts = {
        'respect': respectCount,
        'impressive': impressiveCount,
        'inspired': inspiredCount,
      };

      final userReactMap = await db.query('reactions', columns: ['type'], where: 'post_id = ? AND user_id = ?', whereArgs: [postId, currentUserId]);
      final currentUserReaction = userReactMap.isNotEmpty ? userReactMap.first['type'] as String : null;

      final commentCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM comments WHERE post_id = ?', [postId])) ?? 0;

      final savedMap = await db.query('saved_posts', where: 'post_id = ? AND user_id = ?', whereArgs: [postId, currentUserId]);
      final isSaved = savedMap.isNotEmpty;

      final attendeeCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM rsvps WHERE post_id = ? AND status = "upcoming"', [postId])) ?? 0;

      final rsvpMap = await db.query('rsvps', columns: ['status'], where: 'post_id = ? AND user_id = ?', whereArgs: [postId, currentUserId]);
      final userRsvpStatus = rsvpMap.isNotEmpty ? rsvpMap.first['status'] as String : null;

      posts.add(PostModel.fromMap(
        map,
        reactions: reactionCounts,
        currentUserReaction: currentUserReaction,
        comments: commentCount,
        saved: isSaved,
        attendees: attendeeCount,
        rsvpStatus: userRsvpStatus,
      ));
    }
    return posts;
  }

  Future<List<PostModel>> getUserRsvps(int userId, int currentUserId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT posts.*, 
             users.name AS author_name, 
             users.role AS author_role, 
             users.avatar_index AS author_avatar_index,
             users.is_verified AS author_is_verified,
             CASE 
               WHEN users.role = 'student' THEN 'Class of ' || users.current_year
               WHEN users.role = 'alumni' THEN 'Class of ' || users.graduation_year
               ELSE 'Organizer'
             END AS author_subtitle
      FROM posts
      INNER JOIN rsvps ON posts.id = rsvps.post_id
      INNER JOIN users ON posts.author_id = users.id
      WHERE rsvps.user_id = ? AND rsvps.status != 'cancelled'
      ORDER BY posts.event_date ASC
    ''', [userId]);

    List<PostModel> posts = [];
    for (var map in maps) {
      final postId = map['id'] as int;

      // Reactions count
      final respectCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reactions WHERE post_id = ? AND type = "respect"', [postId])) ?? 0;
      final impressiveCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reactions WHERE post_id = ? AND type = "impressive"', [postId])) ?? 0;
      final inspiredCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reactions WHERE post_id = ? AND type = "inspired"', [postId])) ?? 0;

      final reactionCounts = {
        'respect': respectCount,
        'impressive': impressiveCount,
        'inspired': inspiredCount,
      };

      final userReactMap = await db.query('reactions', columns: ['type'], where: 'post_id = ? AND user_id = ?', whereArgs: [postId, currentUserId]);
      final currentUserReaction = userReactMap.isNotEmpty ? userReactMap.first['type'] as String : null;

      final commentCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM comments WHERE post_id = ?', [postId])) ?? 0;

      final savedMap = await db.query('saved_posts', where: 'post_id = ? AND user_id = ?', whereArgs: [postId, currentUserId]);
      final isSaved = savedMap.isNotEmpty;

      final attendeeCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM rsvps WHERE post_id = ? AND status = "upcoming"', [postId])) ?? 0;

      final rsvpMap = await db.query('rsvps', columns: ['status'], where: 'post_id = ? AND user_id = ?', whereArgs: [postId, currentUserId]);
      final userRsvpStatus = rsvpMap.isNotEmpty ? rsvpMap.first['status'] as String : null;

      posts.add(PostModel.fromMap(
        map,
        reactions: reactionCounts,
        currentUserReaction: currentUserReaction,
        comments: commentCount,
        saved: isSaved,
        attendees: attendeeCount,
        rsvpStatus: userRsvpStatus,
      ));
    }
    return posts;
  }
}
