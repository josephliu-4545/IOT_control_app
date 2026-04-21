import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../gen/app_localizations.dart';
import '../services/locale_provider.dart';
import '../services/tts_service.dart';
import '../config/api_config.dart';
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
  final TextEditingController _esp32CamController = TextEditingController();
  String _esp32CamUrl = '';

  @override
  void initState() {
    super.initState();
    _checkTtsLanguages();
    _loadEsp32CamUrl();
  }

  Future<void> _loadEsp32CamUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('esp32_cam_url') ?? ApiConfig.esp32CamBaseUrl;
    setState(() {
      _esp32CamUrl = savedUrl;
      _esp32CamController.text = savedUrl;
    });
  }

  Future<void> _saveEsp32CamUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32_cam_url', url);
    ApiConfig.updateEsp32CamUrl(url);
    setState(() {
      _esp32CamUrl = url;
    });
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
              
              // ESP32-CAM Configuration
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
                      'ESP32-CAM Configuration',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Camera URL:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _esp32CamController,
                      decoration: InputDecoration(
                        hintText: 'http://192.168.1.100/',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () {
                            final url = _esp32CamController.text.trim();
                            if (url.isNotEmpty) {
                              _saveEsp32CamUrl(url);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ESP32-CAM URL saved'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Current: $_esp32CamUrl',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How to find your ESP32-CAM IP:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '• Connect to ESP32-CAM WiFi hotspot\n' +
                            '• Open Serial Monitor to see IP\n' +
                            '• Or check your router\'s connected devices',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
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
