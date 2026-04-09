// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Health Dashboard';

  @override
  String get dashboardTitle => 'Smart Health Dashboard';

  @override
  String get pulseTooltip => 'Pulse (ESP8266)';

  @override
  String get liveDashboardTooltip => 'Live dashboard';

  @override
  String get healthDetailsTooltip => 'Health details';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get heartRate => 'Heart Rate';

  @override
  String get oxygen => 'Oxygen';

  @override
  String get spo2Level => 'SpO₂ level';

  @override
  String get wifiSignal => 'Wi-Fi Signal';

  @override
  String get battery => 'Battery';

  @override
  String get solar => 'Solar';

  @override
  String get charging => 'Charging';

  @override
  String get idle => 'Idle';

  @override
  String get harvestingEnergy => 'Harvesting energy';

  @override
  String get noSolarInput => 'No solar input';

  @override
  String get waitingForData => 'Waiting for data...';

  @override
  String get stable => 'Stable';

  @override
  String get systemOnline => 'System Online';

  @override
  String get systemOffline => 'System Offline';

  @override
  String get connectingToEsp32Firebase => 'Connecting to ESP32 / Firebase...';

  @override
  String get receivingRealtimeSensorData => 'Receiving real-time sensor data';

  @override
  String get usingFallbackDummyData => 'Using fallback / dummy data';

  @override
  String get cameraPreviewUnavailable => 'Camera preview unavailable';

  @override
  String get glassesCamera => 'Glasses Camera';

  @override
  String get glassesEnv => 'Glasses Env';

  @override
  String get glassesLink => 'Glasses Link';

  @override
  String get tapToToggleDummy => 'Tap to toggle (dummy)';

  @override
  String get ambientTemperature => 'Ambient temperature';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get connected => 'Connected';

  @override
  String get offline => 'Offline';

  @override
  String get smartGlassesStatus => 'Smart glasses status';

  @override
  String get autoSpeakAnalysis => 'Auto speak analysis';

  @override
  String get speak => 'Speak';

  @override
  String get stop => 'Stop';

  @override
  String get analyzeMyEnvironment => 'Analyze My Environment';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get environmentImageUploaded =>
      'Environment image uploaded for analysis.';

  @override
  String failedToAnalyzeEnvironment(String error) {
    return 'Failed to analyze environment: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get liveHealthDashboardTitle => 'Live Health Dashboard';

  @override
  String get refresh => 'Refresh';

  @override
  String get failedToLoadDashboard => 'Failed to load dashboard';

  @override
  String get tryAgain => 'Try again';

  @override
  String get heartHealthTitle => 'Heart Health';

  @override
  String get realTimeHeartRateTrend => 'Real-time heart rate trend';

  @override
  String get pulseRawTitle => 'Pulse (ESP8266 Raw)';

  @override
  String get currentRaw => 'CURRENT RAW';

  @override
  String get waitingForPulseData => 'Waiting for ESP8266 pulse data...';

  @override
  String get waitingForHeartRateData => 'Waiting for heart rate data...';

  @override
  String get latestReading => 'Latest Reading';

  @override
  String flags(String flags) {
    return 'Flags: $flags';
  }

  @override
  String get summary => 'Summary';

  @override
  String historyLastN(int count) {
    return 'History (last $count)';
  }

  @override
  String get noReadingsYet => 'No readings yet.';

  @override
  String get noRecentReadings => 'No recent readings.';

  @override
  String get critical => 'Critical';

  @override
  String get warning => 'Warning';

  @override
  String get normal => 'Normal';
}
