import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = join(dir, 'uptodo.db');

    _db = await openDatabase(
      path,
      version: 6, // ← Tăng version để migrate thêm user_id
      onCreate: (db, version) async {
        print('Creating database version $version');

        // categories with user_id
        await db.execute('''
          CREATE TABLE categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            icon_code_point INTEGER,
            bg_color INTEGER,
            icon_color INTEGER,
            user_id TEXT NOT NULL
          )
        ''');

        // tasks with user_id
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            is_completed INTEGER NOT NULL DEFAULT 0,
            category TEXT,
            priority INTEGER NOT NULL,
            due_date INTEGER,
            time TEXT,
            created_at INTEGER NOT NULL,
            user_id TEXT NOT NULL
          )
        ''');

        await db.execute('CREATE INDEX idx_tasks_due ON tasks(due_date)');
        await db.execute('CREATE INDEX idx_tasks_completed ON tasks(is_completed)');
        await db.execute('CREATE INDEX idx_tasks_user ON tasks(user_id)');  // ← New index

        // profile with user_id
        await db.execute('''
          CREATE TABLE profile(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            bio TEXT,
            avatar_path TEXT,
            user_id TEXT NOT NULL
          )
        ''');

        await db.execute('CREATE INDEX idx_profile_user ON profile(user_id)');  // ← New index
        await db.execute('CREATE INDEX idx_categories_user ON categories(user_id)');  // ← New index

        print('All tables created successfully with user_id support');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print('Upgrading database from $oldVersion to $newVersion');

        if (oldVersion < 6) {
          try {
            // Add user_id column to existing tables
            print('Adding user_id columns...');

            // Check and add user_id to categories
            final categoriesInfo = await db.rawQuery("PRAGMA table_info(categories)");
            final hasUserIdInCategories = categoriesInfo.any((col) => col['name'] == 'user_id');

            if (!hasUserIdInCategories) {
              await db.execute('ALTER TABLE categories ADD COLUMN user_id TEXT');
              print('✅ Added user_id to categories table');
            }

            // Check and add user_id to tasks
            final tasksInfo = await db.rawQuery("PRAGMA table_info(tasks)");
            final hasUserIdInTasks = tasksInfo.any((col) => col['name'] == 'user_id');

            if (!hasUserIdInTasks) {
              await db.execute('ALTER TABLE tasks ADD COLUMN user_id TEXT');
              print('✅ Added user_id to tasks table');
            }

            // Check and add user_id to profile
            final profileInfo = await db.rawQuery("PRAGMA table_info(profile)");
            final hasUserIdInProfile = profileInfo.any((col) => col['name'] == 'user_id');

            if (!hasUserIdInProfile) {
              await db.execute('ALTER TABLE profile ADD COLUMN user_id TEXT');
              print('✅ Added user_id to profile table');
            }

            // Create indexes for user_id
            await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_user ON tasks(user_id)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_user ON categories(user_id)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_profile_user ON profile(user_id)');
            print('✅ Created user_id indexes');

            // OPTION 1: Clear all existing data (recommended for clean separation)
            await db.execute('DELETE FROM tasks');
            await db.execute('DELETE FROM categories');
            await db.execute('DELETE FROM profile');
            print('🧹 Cleared existing data for clean user separation');

            // OPTION 2: Assign existing data to default user (uncomment if needed)
            // await db.execute("UPDATE categories SET user_id = 'default_user' WHERE user_id IS NULL");
            // await db.execute("UPDATE tasks SET user_id = 'default_user' WHERE user_id IS NULL");
            // await db.execute("UPDATE profile SET user_id = 'default_user' WHERE user_id IS NULL");
            // print('📝 Assigned existing data to default user');

          } catch (e) {
            print('❌ Migration error: $e');
            // If migration fails, recreate tables
            await db.execute('DROP TABLE IF EXISTS tasks');
            await db.execute('DROP TABLE IF EXISTS categories');
            await db.execute('DROP TABLE IF EXISTS profile');

            print('🔄 Recreating tables after migration failure...');
            await _createTables(db);
          }
        }

        print('✅ Database migration completed');
      },
      onOpen: (db) async {
        print('Database opened');
      },
    );
    return _db!;
  }

  // Helper method to create tables
  static Future<void> _createTables(Database db) async {
    // Recreate all tables with user_id support
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_code_point INTEGER,
        bg_color INTEGER,
        icon_color INTEGER,
        user_id TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        category TEXT,
        priority INTEGER NOT NULL,
        due_date INTEGER,
        time TEXT,
        created_at INTEGER NOT NULL,
        user_id TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE profile(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        bio TEXT,
        avatar_path TEXT,
        user_id TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_tasks_due ON tasks(due_date)');
    await db.execute('CREATE INDEX idx_tasks_completed ON tasks(is_completed)');
    await db.execute('CREATE INDEX idx_tasks_user ON tasks(user_id)');
    await db.execute('CREATE INDEX idx_categories_user ON categories(user_id)');
    await db.execute('CREATE INDEX idx_profile_user ON profile(user_id)');
  }

  // Reset database method cho debugging
  static Future<void> resetDatabase() async {
    try {
      final dir = await getDatabasesPath();
      final path = join(dir, 'uptodo.db');
      await deleteDatabase(path);
      _db = null;
      print('Database reset successfully');
    } catch (e) {
      print('Error resetting database: $e');
    }
  }

  // Clear all data for specific user
  Future<void> clearUserData(String userId) async {
    final database = await db;
    await database.delete('tasks', where: 'user_id = ?', whereArgs: [userId]);
    await database.delete('categories', where: 'user_id = ?', whereArgs: [userId]);
    await database.delete('profile', where: 'user_id = ?', whereArgs: [userId]);
    print('🧹 Cleared all data for user: $userId');
  }

  // Get database info
  Future<void> printDatabaseInfo() async {
    final database = await db;

    final categoriesCount = await database.rawQuery('SELECT COUNT(*) as count FROM categories');
    final tasksCount = await database.rawQuery('SELECT COUNT(*) as count FROM tasks');
    final profilesCount = await database.rawQuery('SELECT COUNT(*) as count FROM profile');

    print('📊 Database info:');
    print('   Categories: ${categoriesCount.first['count']}');
    print('   Tasks: ${tasksCount.first['count']}');
    print('   Profiles: ${profilesCount.first['count']}');
  }
}