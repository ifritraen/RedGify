import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider with ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    loadTheme();
  }

  Future<void> loadTheme() async {
    try {
      final modeStr = await _secureStorage.read(key: 'theme_mode');
      if (modeStr != null) {
        _themeMode = modeStr == 'light' ? ThemeMode.light : ThemeMode.dark;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      await _secureStorage.write(
        key: 'theme_mode',
        value: _themeMode == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {}
  }
}
