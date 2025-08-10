import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_database.dart';

class CategoryEntity {
  final int? id;
  final String name;
  final int? iconCodePoint; // IconData.codePoint
  final int? bgColor;       // Color.value
  final int? iconColor;     // Color.value

  CategoryEntity({
    this.id,
    required this.name,
    this.iconCodePoint,
    this.bgColor,
    this.iconColor,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'icon_code_point': iconCodePoint,
    'bg_color': bgColor,
    'icon_color': iconColor,
  };

  factory CategoryEntity.fromMap(Map<String, Object?> m) => CategoryEntity(
    id: m['id'] as int?,
    name: m['name'] as String,
    iconCodePoint: m['icon_code_point'] as int?,
    bgColor: m['bg_color'] as int?,
    iconColor: m['icon_color'] as int?,
  );
}

class CategoryDao {
  // Get current user ID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<List<CategoryEntity>> getAll() async {
    final userId = _currentUserId;
    if (userId == null) {
      print('No user logged in, returning empty categories');
      return [];
    }

    final db = await AppDatabase.instance.db;
    final rows = await db.query(
        'categories',
        where: 'user_id = ?',  // ← Filter by user_id
        whereArgs: [userId],
        orderBy: 'id ASC'
    );

    print('Loaded ${rows.length} categories for user: $userId');
    return rows.map((e) => CategoryEntity.fromMap(e)).toList();
  }

  Future<int> insert(CategoryEntity e) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to create categories');
    }

    final db = await AppDatabase.instance.db;
    final categoryMap = e.toMap();
    categoryMap['user_id'] = userId;  // ← Add user_id

    print('Creating category for user: $userId - ${e.name}');
    return db.insert('categories', categoryMap);
  }

  Future<int> update(CategoryEntity e) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to update categories');
    }

    final db = await AppDatabase.instance.db;
    final categoryMap = e.toMap();
    categoryMap['user_id'] = userId;  // ← Ensure user_id is set

    print('Updating category for user: $userId - ${e.name}');
    return db.update(
        'categories',
        categoryMap,
        where: 'id = ? AND user_id = ?',  // ← Only update if belongs to user
        whereArgs: [e.id, userId]
    );
  }

  Future<int> delete(int id) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to delete categories');
    }

    final db = await AppDatabase.instance.db;

    // First, delete all tasks in this category for this user
    await db.delete(
      'tasks',
      where: 'category_id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    print('Deleting category for user: $userId - ID: $id');
    return db.delete(
        'categories',
        where: 'id = ? AND user_id = ?',  // ← Only delete if belongs to user
        whereArgs: [id, userId]
    );
  }

  // Get category count for current user
  Future<int> getCategoryCount() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    final db = await AppDatabase.instance.db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM categories WHERE user_id = ?',
      [userId],
    );

    return result.first['count'] as int;
  }

  // Create default categories for new user
  Future<void> createDefaultCategories() async {
    final userId = _currentUserId;
    if (userId == null) return;

    // Check if user already has categories
    final existingCount = await getCategoryCount();
    if (existingCount > 0) return;

    print('Creating default categories for new user: $userId');

    final defaultCategories = [
      CategoryEntity(
        name: 'Công việc',
        iconCodePoint: Icons.work.codePoint,
        bgColor: 0xFF2196F3,
        iconColor: 0xFFFFFFFF,
      ),
      CategoryEntity(
        name: 'Cá nhân',
        iconCodePoint: Icons.person.codePoint,
        bgColor: 0xFF4CAF50,
        iconColor: 0xFFFFFFFF,
      ),
      CategoryEntity(
        name: 'Học tập',
        iconCodePoint: Icons.school.codePoint,
        bgColor: 0xFFF44336,
        iconColor: 0xFFFFFFFF,
      ),
      CategoryEntity(
        name: 'Sức khỏe',
        iconCodePoint: Icons.health_and_safety.codePoint,
        bgColor: 0xFFFF9800,
        iconColor: 0xFFFFFFFF,
      ),
    ];

    for (final category in defaultCategories) {
      await insert(category);
    }
  }

  // Clear all categories for current user (useful for testing)
  Future<int> clearAllCategories() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    final db = await AppDatabase.instance.db;

    // First clear all tasks
    await db.delete('tasks', where: 'user_id = ?', whereArgs: [userId]);

    // Then clear categories
    print('Clearing all categories for user: $userId');
    return await db.delete(
      'categories',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}