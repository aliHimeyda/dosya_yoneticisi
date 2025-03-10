import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Themeprovider extends ChangeNotifier {
 ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

   // ignore: non_constant_identifier_names
   ThemeProvider() {
    _loadTheme();
  }


  void toggleThemeMode() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
         _saveTheme(_themeMode);
    notifyListeners();
  }
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
  Future<void> _saveTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', themeMode == ThemeMode.dark);
  }
}
