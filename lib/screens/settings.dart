import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../gen/app_localizations.dart';
import '../services/locale_provider.dart';
import '../services/tts_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TtsService _tts = TtsService();
  List<String> _availableTtsLanguages = [];
  bool _ttsChecked = false;

  @override
  void initState() {
    super.initState();
    _checkTtsLanguages();
  }

  Future<void> _checkTtsLanguages() async {
    await _tts.initialize();
    if (mounted) {
      setState(() {
        _availableTtsLanguages = _tts.availableLanguages;
        _ttsChecked = true;
      });
    }
  }

  bool _isTtsAvailableForLocale(Locale locale) {
    if (!_ttsChecked) return true; // Assume available until checked
    return _tts.isLanguageAvailable(locale.toLanguageTag());
  }

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('my', 'MM'),
    Locale('es', 'ES'),
    Locale('fr', 'FR'),
    Locale('de', 'DE'),
    Locale('zh', 'CN'),
    Locale('ja', 'JP'),
    Locale('ru', 'RU'),
    Locale('ar', 'SA'),
    Locale('hi', 'IN'),
  ];

  String _localeLabel(Locale locale) {
    final code = locale.toLanguageTag();
    switch (code) {
      case 'en-US':
        return 'English';
      case 'my-MM':
        return 'Burmese (မြန်မာ)';
      case 'es-ES':
        return 'Español';
      case 'fr-FR':
        return 'Français';
      case 'de-DE':
        return 'Deutsch';
      case 'zh-CN':
        return '中文';
      case 'ja-JP':
        return '日本語';
      case 'ru-RU':
        return 'Русский';
      case 'ar-SA':
        return 'العربية';
      case 'hi-IN':
        return 'हिन्दी';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();

    final currentLocale = localeProvider.locale;
    final selectedTag = currentLocale?.toLanguageTag();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.language,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  color: AppColors.cardBackground,
                ),
                child: Column(
                  children: [
                    for (final locale in supportedLocales)
                      RadioListTile<String>(
                        value: locale.toLanguageTag(),
                        groupValue: selectedTag,
                        title: Row(
                          children: [
                            Expanded(child: Text(_localeLabel(locale))),
                            _buildTtsIndicator(locale),
                          ],
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          localeProvider.setLocale(locale);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_ttsChecked && _availableTtsLanguages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.cardBackground,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Text-to-Speech Availability',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'TTS available',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'TTS unavailable (will use English)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTtsIndicator(Locale locale) {
    if (!_ttsChecked) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final isAvailable = _isTtsAvailableForLocale(locale);
    return Tooltip(
      message: isAvailable
          ? 'Text-to-Speech available'
          : 'Text-to-Speech not available - will use English',
      child: Icon(
        isAvailable ? Icons.check_circle : Icons.warning_amber_rounded,
        color: isAvailable ? Colors.green : Colors.orange,
        size: 18,
      ),
    );
  }
}
