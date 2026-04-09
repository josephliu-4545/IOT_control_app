import 'package:flutter/material.dart';

import 'locale_service.dart';

class LocaleProvider extends ChangeNotifier {
  final LocaleService _service;

  Locale? _locale;

  LocaleProvider({LocaleService? service}) : _service = service ?? LocaleService();

  Locale? get locale => _locale;

  Future<void> init() async {
    _locale = await _service.loadLocale();
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    await _service.saveLocale(locale);
    notifyListeners();
  }
}
