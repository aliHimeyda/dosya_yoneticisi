import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider();

  static const String _languageCodeKey = 'selected_language_code';
  static const List<Locale> supportedLocales = [
    Locale('tr'),
    Locale('en'),
    Locale('ar'),
  ];

  Locale _locale = supportedLocales.first;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_languageCodeKey);

    if (savedLanguageCode == null) {
      return;
    }

    final matchedLocale = supportedLocales.where(
      (locale) => locale.languageCode == savedLanguageCode,
    );

    if (matchedLocale.isNotEmpty) {
      _locale = matchedLocale.first;
      notifyListeners();
    }
  }

  Future<void> setLanguageCode(String languageCode) async {
    if (_locale.languageCode == languageCode) {
      return;
    }

    final matchedLocale = supportedLocales.where(
      (locale) => locale.languageCode == languageCode,
    );

    if (matchedLocale.isEmpty) {
      return;
    }

    _locale = matchedLocale.first;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, languageCode);
  }
}
