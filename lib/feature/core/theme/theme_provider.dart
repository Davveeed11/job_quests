import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemePreference(); // Load theme preference when the provider is created
  }

  // Load theme preference from SharedPreferences
  void _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeString = prefs.getString('themeMode');

    if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system; // Fallback to system
    }
    notifyListeners(); // Notify after loading to update UI
  }

  // Save theme preference to SharedPreferences
  void _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString().split('.').last);
  }

  // Toggle theme mode
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.system; // Cycle to system next
    } else {
      _themeMode = ThemeMode.light; // Cycle to light next
    }
    _saveThemePreference(_themeMode); // Save the new preference
    notifyListeners(); // Notify all listeners about the change
  }

  // Set theme to a specific mode (e.g., from system settings)
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveThemePreference(_themeMode);
      notifyListeners();
    }
  }
}
