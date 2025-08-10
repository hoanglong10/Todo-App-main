import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ThemeChoice { system, light, dark }
enum DefaultSort { newest, priority }

class AppSettings {
  ThemeChoice theme;
  DefaultSort defaultSort;
  bool showCompleted;
  bool use24hTime;
  bool startWeekMonday;
  bool notificationsEnabled; // bạn có thể bỏ nếu không dùng
  TimeOfDay? dailyReminder;  // idem
  int accentColor;           // Color.value
  String languageCode;

  AppSettings({
    this.theme = ThemeChoice.system,
    this.defaultSort = DefaultSort.newest,
    this.showCompleted = true,
    this.use24hTime = false,
    this.startWeekMonday = true,
    this.notificationsEnabled = false,
    this.dailyReminder,
    this.accentColor = 0xFF8E7CFF,
    this.languageCode = 'vi',
  });

  // Get current user ID
  static String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Create user-specific keys
  static String _getUserKey(String key) {
    final userId = _currentUserId ?? 'default';
    return '${userId}_$key';
  }

  // Original keys for reference
  static const _kTheme = 's.theme';
  static const _kSort = 's.sort';
  static const _kCompleted = 's.showCompleted';
  static const _k24h = 's.use24h';
  static const _kMon = 's.monday';
  static const _kNoti = 's.noti';
  static const _kReminderH = 's.reminder.h';
  static const _kReminderM = 's.reminder.m';
  static const _kAccent = 's.accent';
  static const _kLang = 's.lang';

  static Future<AppSettings> load() async {
    final userId = _currentUserId;
    print('Loading settings for user: ${userId ?? 'default'}');

    final sp = await SharedPreferences.getInstance();
    final s = AppSettings();

    // Use user-specific keys
    s.theme = ThemeChoice.values[sp.getInt(_getUserKey(_kTheme)) ?? s.theme.index];
    s.defaultSort = DefaultSort.values[sp.getInt(_getUserKey(_kSort)) ?? s.defaultSort.index];
    s.showCompleted = sp.getBool(_getUserKey(_kCompleted)) ?? s.showCompleted;
    s.use24hTime = sp.getBool(_getUserKey(_k24h)) ?? s.use24hTime;
    s.startWeekMonday = sp.getBool(_getUserKey(_kMon)) ?? s.startWeekMonday;
    s.notificationsEnabled = sp.getBool(_getUserKey(_kNoti)) ?? s.notificationsEnabled;

    final hh = sp.getInt(_getUserKey(_kReminderH));
    final mm = sp.getInt(_getUserKey(_kReminderM));
    if (hh != null && mm != null) {
      s.dailyReminder = TimeOfDay(hour: hh, minute: mm);
    }

    s.accentColor = sp.getInt(_getUserKey(_kAccent)) ?? s.accentColor;
    s.languageCode = sp.getString(_getUserKey(_kLang)) ?? s.languageCode;

    print('Settings loaded for user: ${userId ?? 'default'}');
    return s;
  }

  static Future<void> save(AppSettings s) async {
    final userId = _currentUserId;
    if (userId == null) {
      print('Cannot save settings: No user logged in');
      return;
    }

    print('Saving settings for user: $userId');
    final sp = await SharedPreferences.getInstance();

    // Save with user-specific keys
    await sp.setInt(_getUserKey(_kTheme), s.theme.index);
    await sp.setInt(_getUserKey(_kSort), s.defaultSort.index);
    await sp.setBool(_getUserKey(_kCompleted), s.showCompleted);
    await sp.setBool(_getUserKey(_k24h), s.use24hTime);
    await sp.setBool(_getUserKey(_kMon), s.startWeekMonday);
    await sp.setBool(_getUserKey(_kNoti), s.notificationsEnabled);

    if (s.dailyReminder != null) {
      await sp.setInt(_getUserKey(_kReminderH), s.dailyReminder!.hour);
      await sp.setInt(_getUserKey(_kReminderM), s.dailyReminder!.minute);
    } else {
      await sp.remove(_getUserKey(_kReminderH));
      await sp.remove(_getUserKey(_kReminderM));
    }

    await sp.setInt(_getUserKey(_kAccent), s.accentColor);
    await sp.setString(_getUserKey(_kLang), s.languageCode);

    print('Settings saved for user: $userId');
  }

  // Clear settings for current user (when logging out)
  static Future<void> clearUserSettings() async {
    final userId = _currentUserId;
    if (userId == null) return;

    print('Clearing settings for user: $userId');
    final sp = await SharedPreferences.getInstance();

    final keysToRemove = [
      _getUserKey(_kTheme),
      _getUserKey(_kSort),
      _getUserKey(_kCompleted),
      _getUserKey(_k24h),
      _getUserKey(_kMon),
      _getUserKey(_kNoti),
      _getUserKey(_kReminderH),
      _getUserKey(_kReminderM),
      _getUserKey(_kAccent),
      _getUserKey(_kLang),
    ];

    for (final key in keysToRemove) {
      await sp.remove(key);
    }

    print('Settings cleared for user: $userId');
  }

  // Initialize default settings for new user
  static Future<void> initializeDefaultSettings() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final sp = await SharedPreferences.getInstance();
    final hasSettings = sp.containsKey(_getUserKey(_kTheme));

    if (!hasSettings) {
      print('Initializing default settings for new user: $userId');
      final defaultSettings = AppSettings();
      await save(defaultSettings);
    }
  }
}