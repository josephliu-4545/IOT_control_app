import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  List<String> _availableLanguages = [];

  bool get isInitialized => _isInitialized;
  List<String> get availableLanguages => List.unmodifiable(_availableLanguages);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);

      // Get available languages
      final languages = await _tts.getLanguages;
      if (languages is List) {
        _availableLanguages = languages.cast<String>();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  bool isLanguageAvailable(String languageTag) {
    if (_availableLanguages.isEmpty) return true; // Assume available if we can't check

    // Check exact match first
    if (_availableLanguages.contains(languageTag)) return true;

    // Check language code match (e.g., 'en' matches 'en-US')
    final langCode = languageTag.split('-').first.toLowerCase();
    return _availableLanguages.any((lang) {
      final availableLangCode = lang.split('-').first.toLowerCase();
      return availableLangCode == langCode;
    });
  }

  Future<void> setLanguage(String languageTag) async {
    if (!_isInitialized) await initialize();

    try {
      await _tts.setLanguage(languageTag);
    } catch (e) {
      debugPrint('TTS setLanguage failed for $languageTag: $e');
      // Fallback to English
      try {
        await _tts.setLanguage('en-US');
      } catch (_) {}
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    if (text.isEmpty) return;

    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _tts.pause();
    } catch (e) {
      debugPrint('TTS pause error: $e');
    }
  }

  /// Returns a user-friendly message about language availability
  String? getLanguageAvailabilityMessage(String languageTag) {
    if (_availableLanguages.isEmpty) return null; // Can't determine

    if (isLanguageAvailable(languageTag)) return null; // Available

    final availableLangs = _getAvailableLanguagesDisplay();

    return 'Text-to-Speech for "$languageTag" is not available on this device. '
        'Available languages: $availableLangs. '
        'Falling back to English.';
  }

  String _getAvailableLanguagesDisplay() {
    if (_availableLanguages.isEmpty) return 'None detected';

    // Group by language code and show first variant
    final langMap = <String, List<String>>{};
    for (final lang in _availableLanguages) {
      final code = lang.split('-').first;
      langMap.putIfAbsent(code, () => []).add(lang);
    }

    return langMap.keys.take(5).join(', ') +
        (langMap.length > 5 ? ', ...' : '');
  }
}
