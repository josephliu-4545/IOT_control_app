import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const _key = 'app_locale';

  Future<Locale?> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == null || value.trim().isEmpty) return null;

    final parts = value.split('-');
    if (parts.isEmpty) return null;

    final languageCode = parts[0];
    final countryCode = parts.length >= 2 ? parts[1] : null;

    if (languageCode.isEmpty) return null;

    return Locale(languageCode, countryCode);
  }

  Future<void> saveLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
      return;
    }

    final value = (locale.countryCode == null || locale.countryCode!.isEmpty)
        ? locale.languageCode
        : '${locale.languageCode}-${locale.countryCode}';

    await prefs.setString(_key, value);
  }
}
