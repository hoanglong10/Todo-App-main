import 'package:flutter/material.dart';
import 'package:uptodo/data/settings_service.dart';
import 'package:uptodo/ui/theme/app_theme.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._state);

  final AppSettings _state;
  AppSettings get state => _state;

  ThemeMode get themeMode {
    switch (_state.theme) {
      case ThemeChoice.light:
        return ThemeMode.light;
      case ThemeChoice.dark:
        return ThemeMode.dark;
      case ThemeChoice.system:
        return ThemeMode.system;
    }
  }

  ThemeData get lightTheme => AppTheme.lightFromAccent(Color(_state.accentColor));
  ThemeData get darkTheme  => AppTheme.darkFromAccent(Color(_state.accentColor));

  Future<void> update(void Function(AppSettings s) change) async {
    change(_state);
    await AppSettings.save(_state);
    notifyListeners();
  }
}

// Biến global để SettingsScreen/khác có thể dùng.
late SettingsController settingsController;