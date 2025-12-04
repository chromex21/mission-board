import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { dark, blue }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  static const String _themeModeKey = 'themeMode';
  bool _isDarkMode = true;
  AppThemeMode _currentTheme = AppThemeMode.dark;

  bool get isDarkMode => _isDarkMode;
  AppThemeMode get currentTheme => _currentTheme;

  // Available themes
  final List<Map<String, dynamic>> availableThemes = [
    {
      'name': 'Dark Mode',
      'mode': AppThemeMode.dark,
      'icon': Icons.dark_mode,
      'description': 'Classic dark theme',
      'primaryColor': Color(0xFF8B5CF6),
    },
    {
      'name': 'Blue Aurora',
      'mode': AppThemeMode.blue,
      'icon': Icons.water_drop,
      'description': 'Cool blue accents',
      'primaryColor': Color(0xFF3B82F6),
    },
  ];

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true; // Default to dark
    final themeModeString = prefs.getString(_themeModeKey);
    if (themeModeString != null) {
      _currentTheme = AppThemeMode.values.firstWhere(
        (e) => e.name == themeModeString,
        orElse: () => AppThemeMode.dark,
      );
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_currentTheme == mode) return;
    _currentTheme = mode;
    _isDarkMode = true; // Both themes are dark-based
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }
}
