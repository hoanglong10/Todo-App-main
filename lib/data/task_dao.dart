import 'package:sqflite/sqflite.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_database.dart';
import '../models/task.dart';

class TaskDao {
  static const table = 'tasks';

  // Get current user ID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<List<Task>> getAll() async {
    final userId = _currentUserId;
    if (userId == null) {
      print('No user logged in, returning empty tasks');
      return [];
    }

    final db = await AppDatabase.instance.db;
    final rows = await db.query(
        table,
        where: 'user_id = ?',  // ← Filter by user_id
        whereArgs: [userId],
        orderBy: 'created_at DESC'
    );

    print('Loaded ${rows.length} tasks for user: $userId');
    return rows.map((e) => Task.fromMap(e)).toList();
  }

  Future<int> insert(Task t) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to create tasks');
    }

    final db = await AppDatabase.instance.db;
    final taskMap = {
      ...t.toMap()..remove('id'),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'user_id': userId,  // ← Add user_id
    };

    print('Creating task for user: $userId - ${t.title}');
    final id = await db.insert(table, taskMap);
    return id;
  }

  Future<int> update(Task t) async {
    if (t.id == null) throw ArgumentError('Task id is null');

    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to update tasks');
    }

    final db = await AppDatabase.instance.db;
    final taskMap = t.toMap()..remove('created_at');
    taskMap['user_id'] = userId;  // ← Ensure user_id is set

    print('Updating task for user: $userId - ${t.title}');
    return db.update(
        table,
        taskMap,
        where: 'id = ? AND user_id = ?',  // ← Only update if belongs to user
        whereArgs: [t.id, userId]
    );
  }

  Future<int> delete(int id) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to delete tasks');
    }

    final db = await AppDatabase.instance.db;
    print('Deleting task for user: $userId - ID: $id');
    return db.delete(
        table,
        where: 'id = ? AND user_id = ?',  // ← Only delete if belongs to user
        whereArgs: [id, userId]
    );
  }

  Future<int> toggleCompleted(int id, bool completed) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to toggle tasks');
    }

    final db = await AppDatabase.instance.db;
    print('Toggling task completion for user: $userId - ID: $id - Completed: $completed');
    return db.update(
        table,
        {'is_completed': completed ? 1 : 0},
        where: 'id = ? AND user_id = ?',  // ← Only update if belongs to user
        whereArgs: [id, userId]
    );
  }

  // Get tasks by completion status for current user
  Future<List<Task>> getTasksByCompletion(bool completed) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final db = await AppDatabase.instance.db;
    final rows = await db.query(
        table,
        where: 'user_id = ? AND is_completed = ?',
        whereArgs: [userId, completed ? 1 : 0],
        orderBy: 'created_at DESC'
    );

    return rows.map((e) => Task.fromMap(e)).toList();
  }

  // Get task count for current user
  Future<int> getTaskCount() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    final db = await AppDatabase.instance.db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table WHERE user_id = ?',
      [userId],
    );

    return result.first['count'] as int;
  }

  // Get completed task count for current user
  Future<int> getCompletedTaskCount() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    final db = await AppDatabase.instance.db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table WHERE user_id = ? AND is_completed = 1',
      [userId],
    );

    return result.first['count'] as int;
  }

  // Clear all tasks for current user (useful for testing)
  Future<int> clearAllTasks() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    final db = await AppDatabase.instance.db;
    print('Clearing all tasks for user: $userId');
    return await db.delete(
      table,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}