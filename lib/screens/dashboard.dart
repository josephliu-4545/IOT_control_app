// lib/screens/dashboard.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../gen/app_localizations.dart';
import '../main.dart'; // for DashboardViewModel
import '../models/environment_analysis.dart';
import '../services/environment_analysis_api_service.dart';
import '../services/tts_service.dart';
import '../services/esp32_cam_service.dart';
import '../services/voice_assistant_service.dart';
import 'settings.dart';
import 'device_diagnostics.dart';
import '../utils/constants.dart';
import 'health.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/';

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TtsService _tts = TtsService();
  late final VoiceAssistantService _voiceAssistant;
  bool _autoSpeakEnvAnalysis = true;
  String? _lastSpokenEnvSummary;
  bool _ttsReady = false;
  String? _lastTtsLanguage;
  bool _showedTtsWarning = false;

  bool _isEnvAnalyzing = false;

  bool _useCapturePreview = false;
  Timer? _capturePreviewTimer;
  Uint8List? _latestPreviewJpeg;
  DateTime? _latestPreviewAt;
  bool _isFetchingPreviewFrame = false;
  int _previewTick = 0;
  String? _esp32CamErrorMessage;
  String? _voiceLocale;

  @override
  void initState() {
    super.initState();
    _voiceAssistant = VoiceAssistantService(
      imageProvider: _provideVoiceAssistantImage,
    );
    debugPrint(
      'ESP32-CAM PREVIEW URL (stream): ${ApiConfig.esp32CamStreamUrl}',
    );
    debugPrint(
      'ESP32-CAM PREVIEW URL (capture): ${ApiConfig.esp32CamCaptureUrl}',
    );
    _useCapturePreview = true;
    debugPrint('ESP32-CAM PREVIEW MODE: capture (forced)');
    _startCapturePreview();

    _initTts();
    _voiceAssistant.addListener(_onVoiceAssistantChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_voiceLocale == locale) return;
    _voiceLocale = locale;
    unawaited(_voiceAssistant.initialize(localeId: locale));
  }

  void _onVoiceAssistantChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    try {
      await _tts.initialize();
      if (!mounted) return;
      setState(() {
        _ttsReady = true;
      });
    } catch (e) {
      debugPrint('TTS INIT ERROR: $e');
    }
  }

  Future<void> _maybeUpdateTtsLanguage(BuildContext context) async {
    if (!_ttsReady) return;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    if (_lastTtsLanguage == tag) return;
    _lastTtsLanguage = tag;

    // Check if language is available and show warning if not
    if (!_showedTtsWarning && !_tts.isLanguageAvailable(tag)) {
      _showedTtsWarning = true;
      final message = _tts.getLanguageAvailabilityMessage(tag);
      if (message != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTtsWarning(context, message);
        });
      }
    }

    await _tts.setLanguage(tag);
  }

  void _showTtsWarning(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _capturePreviewTimer?.cancel();
    _voiceAssistant.removeListener(_onVoiceAssistantChanged);
    _voiceAssistant.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakEnvSummary(String text) async {
    if (!_ttsReady) return;
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    await _tts.stop();
    await _tts.speak(cleaned);
  }

  Future<void> _stopSpeaking() async {
    if (!_ttsReady) return;
    await _tts.stop();
  }

  void _maybeAutoSpeak(EnvironmentAnalysis? analysis) {
    if (!_autoSpeakEnvAnalysis) return;
    final summary = analysis?.summary;
    if (summary == null) return;
    final cleaned = summary.trim();
    if (cleaned.isEmpty) return;
    if (_lastSpokenEnvSummary == cleaned) return;
    _lastSpokenEnvSummary = cleaned;
    _speakEnvSummary(cleaned);
  }

  void _startCapturePreview() {
    if (_capturePreviewTimer != null) return;
    debugPrint('ESP32-CAM CAPTURE PREVIEW: starting timer (2s)');
    _capturePreviewTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _previewTick += 1;
      if (_previewTick % 10 == 0) {
        debugPrint('ESP32-CAM CAPTURE PREVIEW: tick=$_previewTick');
      }
      _fetchPreviewFrame();
    });
    _fetchPreviewFrame();
  }

  Future<void> _fetchPreviewFrame() async {
    if (!mounted) return;
    if (_isFetchingPreviewFrame) return;
    _isFetchingPreviewFrame = true;
    try {
      final bytes = await Esp32CamService().captureJpeg(
        captureUrl: ApiConfig.esp32CamCaptureUrl,
      );
      if (!mounted) return;
      if (bytes.isEmpty) {
        debugPrint('ESP32-CAM CAPTURE PREVIEW: received EMPTY bytes');
      } else {
        debugPrint('ESP32-CAM CAPTURE PREVIEW: received ${bytes.length} bytes');
      }
      setState(() {
        _latestPreviewJpeg = bytes;
        _latestPreviewAt = DateTime.now();
        _esp32CamErrorMessage = null;
      });
    } catch (e) {
      debugPrint('ESP32-CAM CAPTURE PREVIEW ERROR: $e');
      if (!mounted) return;
      setState(() {
        _esp32CamErrorMessage =
            'Failed to connect to ESP32-CAM. Please check your connection.';
      });
    } finally {
      _isFetchingPreviewFrame = false;
    }
  }

  Future<Uint8List> _provideVoiceAssistantImage() async {
    final preview = _latestPreviewJpeg;
    final capturedAt = _latestPreviewAt;
    if (preview != null &&
        preview.isNotEmpty &&
        capturedAt != null &&
        DateTime.now().difference(capturedAt) < const Duration(seconds: 8)) {
      debugPrint(
        'VOICE ASSISTANT CAMERA: reusing preview frame (${preview.length} bytes)',
      );
      return preview;
    }

    // Avoid overlapping the fallback capture with the periodic preview poll.
    while (_isFetchingPreviewFrame) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    debugPrint('VOICE ASSISTANT CAMERA: capturing a fresh fallback frame');
    return Esp32CamService().captureJpeg(
      captureUrl: ApiConfig.esp32CamCaptureUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final viewModel = context.watch<DashboardViewModel>();
    final snapshot = viewModel.currentSnapshot;
    final isLoading = viewModel.isLoading;
    final EnvironmentAnalysis? latestEnv = viewModel.latestEnvironmentAnalysis;
    debugPrint("ENV MODEL: $latestEnv");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeUpdateTtsLanguage(context);
      _maybeAutoSpeak(latestEnv);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          IconButton(
            tooltip: l10n.healthDetailsTooltip,
            icon: const Icon(Icons.monitor_heart),
            onPressed: () {
              Navigator.of(context).pushNamed(HealthScreen.routeName);
            },
          ),
          IconButton(
            tooltip: 'Heart Rate Analysis',
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed('/heart-rate-analysis');
            },
          ),
          IconButton(
            tooltip: 'Danger Detection',
            icon: const Icon(Icons.shield_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed('/danger-detection');
            },
          ),
          IconButton(
            tooltip: l10n.settingsTooltip,
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(SettingsScreen.routeName);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildHeader(context, snapshot, isLoading),
            const SizedBox(height: AppSpacing.md),

            _buildVoiceAssistantCard(context),
            const SizedBox(height: AppSpacing.md),

            _buildEnvironmentAnalysisCard(context, latestEnv),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceAssistantCard(BuildContext context) {
    final theme = Theme.of(context);
    final state = _voiceAssistant.state;
    final isListening = state == VoiceAssistantState.listening;
    final isProcessing = state == VoiceAssistantState.processing;
    final isMuted = state == VoiceAssistantState.muted;
    final hasError = state == VoiceAssistantState.error;
    final color = isMuted || hasError
        ? AppColors.accentRed
        : isListening
        ? AppColors.accentGreen
        : AppColors.accentBlue;
    final icon = isMuted
        ? Icons.volume_off
        : isProcessing
        ? Icons.hourglass_top_rounded
        : _voiceAssistant.isBusy
        ? Icons.stop_rounded
        : Icons.mic_rounded;
    final actionLabel = _voiceAssistant.isBusy
        ? 'Stop voice assistant'
        : 'Start voice assistant';

    Future<void> activate() async {
      if (_voiceAssistant.isBusy) {
        await _voiceAssistant.stop();
      } else {
        await _voiceAssistant.startListening(
          localeId: Localizations.localeOf(context).toLanguageTag(),
        );
      }
    }

    return Semantics(
      container: true,
      label: 'Voice assistant',
      hint:
          'Double tap the microphone or hold the physical Volume Up button to ask what is in front of you.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .5)),
          gradient: LinearGradient(
            colors: [AppColors.cardBackground, color.withValues(alpha: .1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Voice assistant',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Ask “What’s in front of me?”',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              button: true,
              label: actionLabel,
              child: Tooltip(
                message: actionLabel,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: activate,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: .35),
                          blurRadius: isListening ? 28 : 16,
                          spreadRadius: isListening ? 7 : 2,
                        ),
                      ],
                    ),
                    child: isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(38),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(icon, size: 52, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: Text(
                _voiceAssistant.statusMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Shortcut: hold Volume Up • Short press still changes volume',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic snapshot, bool isLoading) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bool isOnline = snapshot?.isOnline ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground,
            (isOnline ? AppColors.accentGreen : AppColors.accentRed)
                .withOpacity(0.08),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.check_circle : Icons.error,
            color: isOnline ? AppColors.accentGreen : AppColors.accentRed,
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOnline ? l10n.systemOnline : l10n.systemOffline,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isLoading
                    ? l10n.connectingToEsp32Firebase
                    : (isOnline
                          ? l10n.receivingRealtimeSensorData
                          : 'No live cloud sensor data received'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentAnalysisCard(
    BuildContext context,
    EnvironmentAnalysis? analysis,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final summary = analysis?.summary?.trim();
    final hasAnalysis =
        summary != null &&
        summary.isNotEmpty &&
        !summary.toLowerCase().contains('not configured');
    final riskLevel = analysis?.riskLevel?.trim().toLowerCase();
    final riskColor = switch (riskLevel) {
      'high' => AppColors.accentRed,
      'medium' => Colors.orange,
      'low' => AppColors.accentGreen,
      _ => AppColors.textSecondary,
    };

    Future<void> onAnalyzePressed() async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        if (_isEnvAnalyzing) return;
        setState(() {
          _isEnvAnalyzing = true;
        });

        final languageTag = Localizations.localeOf(context).toLanguageTag();

        final jpegBytes = await Esp32CamService().captureJpeg(
          captureUrl: ApiConfig.esp32CamCaptureUrl,
        );
        await EnvironmentAnalysisApiService().uploadEnvironmentImage(
          jpegBytes: jpegBytes,
          languageTag: languageTag,
        );

        messenger.showSnackBar(
          SnackBar(content: Text(l10n.environmentImageUploaded)),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.failedToAnalyzeEnvironment(e.toString())),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isEnvAnalyzing = false;
          });
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        color: AppColors.cardBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Environment scan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Camera preview and AI image classification',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'AI',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _useCapturePreview
                  ? (_esp32CamErrorMessage != null
                        ? Container(
                            color: AppColors.cardBackground,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_off,
                                  color: AppColors.textSecondary,
                                  size: 32,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Camera Offline',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _esp32CamErrorMessage!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Check the device address and Wi-Fi connection.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _fetchPreviewFrame,
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text('Retry'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => Navigator.pushNamed(
                                        context,
                                        DeviceDiagnosticsScreen.routeName,
                                      ),
                                      icon: const Icon(Icons.tune, size: 18),
                                      label: const Text('Diagnostics'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : (_latestPreviewJpeg == null
                              ? Container(
                                  color: AppColors.cardBackground,
                                  alignment: Alignment.center,
                                  child: const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Image.memory(
                                  _latestPreviewJpeg!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint(
                                      'ESP32-CAM PREVIEW Image.memory error: $error',
                                    );
                                    return Container(
                                      color: AppColors.cardBackground,
                                      alignment: Alignment.center,
                                      child: Text(
                                        l10n.cameraPreviewUnavailable,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    );
                                  },
                                )))
                  : Image.network(
                      ApiConfig.esp32CamStreamUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(
                          'ESP32-CAM STREAM PREVIEW ERROR for ${ApiConfig.esp32CamStreamUrl}: $error',
                        );

                        if (!_useCapturePreview) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() {
                              _useCapturePreview = true;
                            });
                            _startCapturePreview();
                          });
                        }

                        return Container(
                          color: AppColors.cardBackground,
                          alignment: Alignment.center,
                          child: Text(
                            l10n.cameraPreviewUnavailable,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasAnalysis) ...[
            Row(
              children: [
                Text(
                  'Latest result',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    riskLevel == null || riskLevel == 'unknown'
                        ? 'CLASSIFIED'
                        : '${riskLevel.toUpperCase()} RISK',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(summary, style: theme.textTheme.bodyMedium),
            if (analysis!.lighting != null &&
                analysis.lighting!.toLowerCase() != 'unknown') ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Lighting: ${analysis.lighting}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (analysis.hazards.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: analysis.hazards
                    .map(
                      (hazard) => Chip(
                        avatar: const Icon(Icons.warning_amber, size: 16),
                        label: Text(hazard),
                      ),
                    )
                    .toList(),
              ),
            ],
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.image_search_outlined,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'No environment scan yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Capture an image to identify what the camera can see.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.autoSpeakAnalysis),
              value: _autoSpeakEnvAnalysis,
              onChanged: (v) {
                setState(() {
                  _autoSpeakEnvAnalysis = v;
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      (analysis?.summary == null ||
                          (analysis!.summary ?? '').trim().isEmpty)
                      ? null
                      : () => _speakEnvSummary(analysis.summary!),
                  icon: const Icon(Icons.volume_up),
                  label: Text(l10n.speak),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _ttsReady ? _stopSpeaking : null,
                  icon: const Icon(Icons.stop),
                  label: Text(l10n.stop),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isEnvAnalyzing ? null : onAnalyzePressed,
              icon: const Icon(Icons.analytics),
              label: Text(
                _isEnvAnalyzing ? l10n.analyzing : l10n.analyzeMyEnvironment,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
