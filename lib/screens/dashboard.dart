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
import 'settings.dart';
import '../utils/constants.dart';
import '../widgets/sensor_card.dart';
import 'health.dart';
import 'live_dashboard.dart';
import 'pulse_live.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/';

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  // Local dummy state for smart glasses ecosystem.
  bool _glassesConnected = true;
  bool _glassesCameraOn = false;
  double _glassesTemperatureC = 26.5;

  final TtsService _tts = TtsService();
  bool _autoSpeakEnvAnalysis = true;
  String? _lastSpokenEnvSummary;
  bool _ttsReady = false;
  String? _lastTtsLanguage;
  bool _showedTtsWarning = false;

  bool _isEnvAnalyzing = false;

  bool _useCapturePreview = false;
  Timer? _capturePreviewTimer;
  Uint8List? _latestPreviewJpeg;
  bool _isFetchingPreviewFrame = false;
  int _previewTick = 0;

  @override
  void initState() {
    super.initState();
    print('ESP32-CAM PREVIEW URL (stream): ${ApiConfig.esp32CamStreamUrl}');
    print('ESP32-CAM PREVIEW URL (capture): ${ApiConfig.esp32CamCaptureUrl}');
    _useCapturePreview = true;
    print('ESP32-CAM PREVIEW MODE: capture (forced)');
    _startCapturePreview();

    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.initialize();
      if (!mounted) return;
      setState(() {
        _ttsReady = true;
      });
    } catch (e) {
      print('TTS INIT ERROR: $e');
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
    print('ESP32-CAM CAPTURE PREVIEW: starting timer (700ms)');
    _capturePreviewTimer = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) {
        _previewTick += 1;
        if (_previewTick % 10 == 0) {
          print('ESP32-CAM CAPTURE PREVIEW: tick=$_previewTick');
        }
        _fetchPreviewFrame();
      },
    );
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
        print('ESP32-CAM CAPTURE PREVIEW: received EMPTY bytes');
      } else {
        print('ESP32-CAM CAPTURE PREVIEW: received ${bytes.length} bytes');
      }
      setState(() {
        _latestPreviewJpeg = bytes;
      });
    } catch (e) {
      print('ESP32-CAM CAPTURE PREVIEW ERROR: $e');
    } finally {
      _isFetchingPreviewFrame = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final viewModel = context.watch<DashboardViewModel>();
    final snapshot = viewModel.currentSnapshot;
    final isLoading = viewModel.isLoading;
    final EnvironmentAnalysis? latestEnv = viewModel.latestEnvironmentAnalysis;
    print("ENV MODEL: $latestEnv");

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
            tooltip: l10n.pulseTooltip,
            icon: const Icon(Icons.show_chart),
            onPressed: () {
              Navigator.of(context).pushNamed(PulseLiveScreen.routeName);
            },
          ),
          IconButton(
            tooltip: l10n.liveDashboardTooltip,
            icon: const Icon(Icons.insights),
            onPressed: () {
              Navigator.of(context).pushNamed(LiveDashboardScreen.routeName);
            },
          ),
          IconButton(
            tooltip: l10n.healthDetailsTooltip,
            icon: const Icon(Icons.monitor_heart),
            onPressed: () {
              Navigator.of(context).pushNamed(HealthScreen.routeName);
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, snapshot, isLoading),
              const SizedBox(height: AppSpacing.md),

              _buildEnvironmentAnalysisCard(context, latestEnv),
              const SizedBox(height: AppSpacing.md),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  children: [
                    SensorCard(
                      title: l10n.heartRate,
                      value: snapshot?.heartRateBpm.toString() ?? '--',
                      unit: 'BPM',
                      icon: Icons.favorite,
                      accentColor: AppColors.accentRed,
                      subtitle: snapshot == null
                          ? l10n.waitingForData
                          : l10n.stable,
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(HealthScreen.routeName);
                      },
                    ),
                    SensorCard(
                      title: l10n.oxygen,
                      value: snapshot?.oxygenPercent.toString() ?? '--',
                      unit: '%',
                      icon: Icons.bubble_chart,
                      accentColor: AppColors.accentBlue,
                      subtitle: l10n.spo2Level,
                    ),
                    SensorCard(
                      title: l10n.wifiSignal,
                      value: snapshot?.wifiSignal.toString() ?? '--',
                      unit: '%',
                      icon: Icons.wifi,
                      accentColor: AppColors.accentGreen,
                      subtitle: snapshot == null
                          ? null
                          : _wifiLabel(snapshot.wifiSignal),
                      onTap: () => _showWifiInfoDialog(context, snapshot),
                    ),
                    SensorCard(
                      title: l10n.battery,
                      value: snapshot?.batteryLevel.toString() ?? '--',
                      unit: '%',
                      icon: Icons.battery_full,
                      accentColor: Colors.amber,
                      subtitle: snapshot == null
                          ? null
                          : _batteryLabel(snapshot.batteryLevel),
                      onTap: () => _showBatteryDetailsSheet(context, snapshot),
                    ),
                    SensorCard(
                      title: l10n.solar,
                      value: snapshot == null
                          ? '--'
                          : (snapshot.isChargingSolar ? l10n.charging : l10n.idle),
                      icon: Icons.wb_sunny,
                      accentColor: Colors.orangeAccent,
                      subtitle: snapshot == null
                          ? null
                          : (snapshot.isChargingSolar
                              ? l10n.harvestingEnergy
                              : l10n.noSolarInput),
                      onTap: () => _showSolarInfoDialog(context, snapshot),
                    ),
                    // Smart glasses: camera control.
                    SensorCard(
                      title: l10n.glassesCamera,
                      value: _glassesCameraOn ? l10n.on : l10n.off,
                      icon: Icons.videocam,
                      accentColor: AppColors.accentBlue,
                      subtitle: l10n.tapToToggleDummy,
                      onTap: () => _showGlassesCameraSheet(context),
                    ),
                    // Smart glasses: environment / temperature monitor.
                    SensorCard(
                      title: l10n.glassesEnv,
                      value: '${_glassesTemperatureC.toStringAsFixed(1)}',
                      unit: '°C',
                      icon: Icons.thermostat,
                      accentColor: AppColors.accentGreen,
                      subtitle: l10n.ambientTemperature,
                      onTap: () => _showGlassesEnvironmentDialog(context),
                    ),
                    // Smart glasses: connection status.
                    SensorCard(
                      title: l10n.glassesLink,
                      value: _glassesConnected ? l10n.connected : l10n.offline,
                      icon: Icons.vrpano,
                      accentColor:
                          _glassesConnected ? AppColors.accentGreen : AppColors.accentRed,
                      subtitle: l10n.smartGlassesStatus,
                      onTap: () => _showGlassesConnectionDialog(context),
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

  Widget _buildHeader(
    BuildContext context,
    dynamic snapshot,
    bool isLoading,
  ) {
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
                        : l10n.usingFallbackDummyData),
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
          SnackBar(content: Text(l10n.failedToAnalyzeEnvironment(e.toString()))),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _useCapturePreview
                  ? (_latestPreviewJpeg == null
                      ? Container(
                          color: AppColors.cardBackground,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Image.memory(
                          _latestPreviewJpeg!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) {
                            print('ESP32-CAM PREVIEW Image.memory error: $error');
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
                        ))
                  : Image.network(
                      ApiConfig.esp32CamStreamUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print(
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
          (analysis != null)
              ? Text(
                  'ENV FOUND: ${analysis.summary}',
                  style: theme.textTheme.bodyMedium,
                )

              : Text(
                  'ENV IS NULL',
                  style: theme.textTheme.bodyMedium,
                ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.autoSpeakAnalysis),
            value: _autoSpeakEnvAnalysis,
            onChanged: (v) {
              setState(() {
                _autoSpeakEnvAnalysis = v;
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (analysis?.summary == null ||
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

  String _wifiLabel(int value) {
    if (value >= 80) return 'Excellent';
    if (value >= 60) return 'Good';
    if (value >= 40) return 'Fair';
    return 'Weak';
  }

  String _batteryLabel(int value) {
    if (value >= 80) return 'High';
    if (value >= 50) return 'Medium';
    if (value >= 20) return 'Low';
    return 'Critical';
  }

  void _showBatteryDetailsSheet(BuildContext context, dynamic snapshot) {
    if (snapshot == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final int level = snapshot.batteryLevel;
        final bool charging = snapshot.isChargingSolar;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.battery_full, color: Colors.amber),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Battery details'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Level: $level%'),
              const SizedBox(height: AppSpacing.sm),
              Text('Status: ${_batteryLabel(level)}'),
              const SizedBox(height: AppSpacing.sm),
              Text('Solar charging: ${charging ? 'Active' : 'Inactive'}'),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  void _showWifiInfoDialog(BuildContext context, dynamic snapshot) {
    if (snapshot == null) return;
    final int strength = snapshot.wifiSignal;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Wi-Fi signal'),
          content: Text('Strength: $strength% (${_wifiLabel(strength)})'),
        );
      },
    );
  }

  void _showSolarInfoDialog(BuildContext context, dynamic snapshot) {
    if (snapshot == null) return;
    final bool charging = snapshot.isChargingSolar;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Solar status'),
          content: Text(
            charging
                ? 'Panels are actively charging the system.'
                : 'No significant solar charging detected.',
          ),
        );
      },
    );
  }

  void _showGlassesCameraSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool localCameraState = _glassesCameraOn;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.videocam, color: AppColors.accentBlue),
                      SizedBox(width: AppSpacing.sm),
                      Text('Smart glasses camera'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Camera (dummy toggle)'),
                      Switch(
                        value: localCameraState,
                        onChanged: (value) {
                          setModalState(() {
                            localCameraState = value;
                          });
                          setState(() {
                            _glassesCameraOn = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'In the future this will send a command to Firebase/ESP32 to turn the camera on or off.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGlassesEnvironmentDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Glasses environment'),
          content: Text(
            'Ambient temperature around smart glasses: '
            '${_glassesTemperatureC.toStringAsFixed(1)}Â°C (dummy)',
          ),
        );
      },
    );
  }

  void _showGlassesConnectionDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Glasses connection'),
          content: Text(
            _glassesConnected
                ? 'Smart glasses are marked as connected (dummy state).'
                : 'Smart glasses are offline.',
          ),
        );
      },
    );
  }
}