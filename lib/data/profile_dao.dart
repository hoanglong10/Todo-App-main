import 'package:sqflite/sqflite.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile.dart';
import 'app_database.dart';

class ProfileDao {
  // Get current user ID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<Profile?> getProfile() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        print('No user logged in, cannot get profile');
        return null;
      }

      final db = await AppDatabase.instance.db;
      print('Getting profile for user: $userId');

      final rows = await db.query(
          'profile',
          where: 'user_id = ?',  // ← Filter by user_id
          whereArgs: [userId],
          orderBy: 'id DESC',
          limit: 1
      );
      print('Profile query result: ${rows.length} rows for user: $userId');

      if (rows.isEmpty) {
        print('No profile found for user: $userId');
        return null;
      }

      final profile = Profile.fromMap(rows.first);
      print('Profile loaded for user: $userId - ${profile.name}');
      return profile;
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  Future<int> insert(Profile p) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be logged in to create profile');
      }

      final db = await AppDatabase.instance.db;
      print('Inserting profile for user: $userId - ${p.name}');

      final profileMap = p.toMap();
      profileMap['user_id'] = userId;  // ← Add user_id

      final id = await db.insert('profile', profileMap);
      print('Profile inserted with id: $id for user: $userId');
      return id;
    } catch (e) {
      print('Error inserting profile: $e');
      rethrow;
    }
  }

  Future<int> update(Profile p) async {
    try {
      if (p.id == null) throw Exception('Profile id is null');

      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be logged in to update profile');
      }

      final db = await AppDatabase.instance.db;
      print('Updating profile for user: $userId - id: ${p.id}');

      final profileMap = p.toMap();
      profileMap['user_id'] = userId;  // ← Ensure user_id is set

      final result = await db.update(
          'profile',
          profileMap,
          where: 'id = ? AND user_id = ?',  // ← Only update if belongs to user
          whereArgs: [p.id, userId]
      );
      print('Profile update affected $result rows for user: $userId');
      return result;
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User must be logged in to delete profile');
      }

      final db = await AppDatabase.instance.db;
      print('Deleting profile for user: $userId - id: $id');

      final result = await db.delete(
          'profile',
          where: 'id = ? AND user_id = ?',  // ← Only delete if belongs to user
          whereArgs: [id, userId]
      );
      print('Profile delete affected $result rows for user: $userId');
      return result;
    } catch (e) {
      print('Error deleting profile: $e');
      rethrow;
    }
  }

  // Create default profile for new user
  Future<void> createDefaultProfile() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if profile already exists
    final existingProfile = await getProfile();
    if (existingProfile != null) return;

    print('Creating default profile for new user: $userId');

    final defaultProfile = Profile(
      name: currentUser.displayName ?? currentUser.email?.split('@').first ?? 'User',
      email: currentUser.email ?? '',
      bio: 'UpTodo user',
      avatarPath: null,
    );

    await insert(defaultProfile);
  }

  // Clear profile for current user (when logging out)
  Future<int> clearUserProfile() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    final db = await AppDatabase.instance.db;
    print('Clearing profile for user: $userId');
    return await db.delete(
      'profile',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}