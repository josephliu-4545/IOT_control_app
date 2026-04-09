// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Smartes Gesundheits-Dashboard';

  @override
  String get dashboardTitle => 'Smartes Gesundheits-Dashboard';

  @override
  String get pulseTooltip => 'Puls (ESP8266)';

  @override
  String get liveDashboardTooltip => 'Live-Dashboard';

  @override
  String get healthDetailsTooltip => 'Gesundheitsdetails';

  @override
  String get settingsTooltip => 'Einstellungen';

  @override
  String get heartRate => 'Herzfrequenz';

  @override
  String get oxygen => 'Sauerstoff';

  @override
  String get spo2Level => 'SpO₂-Wert';

  @override
  String get wifiSignal => 'WLAN-Signal';

  @override
  String get battery => 'Batterie';

  @override
  String get solar => 'Solar';

  @override
  String get charging => 'Lädt';

  @override
  String get idle => 'Leerlauf';

  @override
  String get harvestingEnergy => 'Energie wird gesammelt';

  @override
  String get noSolarInput => 'Kein Solar-Eingang';

  @override
  String get waitingForData => 'Warte auf Daten...';

  @override
  String get stable => 'Stabil';

  @override
  String get systemOnline => 'System online';

  @override
  String get systemOffline => 'System offline';

  @override
  String get connectingToEsp32Firebase => 'Verbinde mit ESP32 / Firebase...';

  @override
  String get receivingRealtimeSensorData => 'Empfange Sensordaten in Echtzeit';

  @override
  String get usingFallbackDummyData => 'Verwende Fallback-/Dummy-Daten';

  @override
  String get cameraPreviewUnavailable => 'Kamera-Vorschau nicht verfügbar';

  @override
  String get glassesCamera => 'Brillen-Kamera';

  @override
  String get glassesEnv => 'Brillen-Umgebung';

  @override
  String get glassesLink => 'Brillen-Verbindung';

  @override
  String get tapToToggleDummy => 'Tippen zum Umschalten (Dummy)';

  @override
  String get ambientTemperature => 'Umgebungstemperatur';

  @override
  String get on => 'An';

  @override
  String get off => 'Aus';

  @override
  String get connected => 'Verbunden';

  @override
  String get offline => 'Offline';

  @override
  String get smartGlassesStatus => 'Status der smarten Brille';

  @override
  String get autoSpeakAnalysis => 'Analyse automatisch vorlesen';

  @override
  String get speak => 'Sprechen';

  @override
  String get stop => 'Stopp';

  @override
  String get analyzeMyEnvironment => 'Meine Umgebung analysieren';

  @override
  String get analyzing => 'Analysiere...';

  @override
  String get environmentImageUploaded =>
      'Umgebungsbild zur Analyse hochgeladen.';

  @override
  String failedToAnalyzeEnvironment(String error) {
    return 'Umgebung konnte nicht analysiert werden: $error';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get liveHealthDashboardTitle => 'Live Gesundheits-Dashboard';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get failedToLoadDashboard => 'Dashboard konnte nicht geladen werden';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get heartHealthTitle => 'Herzgesundheit';

  @override
  String get realTimeHeartRateTrend => 'Echtzeit-Herzfrequenzverlauf';

  @override
  String get pulseRawTitle => 'Puls (ESP8266 Roh)';

  @override
  String get currentRaw => 'AKTUELL ROH';

  @override
  String get waitingForPulseData => 'Warte auf ESP8266-Pulsdaten...';

  @override
  String get waitingForHeartRateData => 'Warte auf Herzfrequenzdaten...';

  @override
  String get latestReading => 'Letzte Messung';

  @override
  String flags(String flags) {
    return 'Markierungen: $flags';
  }

  @override
  String get summary => 'Zusammenfassung';

  @override
  String historyLastN(int count) {
    return 'Verlauf (letzte $count)';
  }

  @override
  String get noReadingsYet => 'Noch keine Messwerte.';

  @override
  String get noRecentReadings => 'Keine aktuellen Messwerte.';

  @override
  String get critical => 'Kritisch';

  @override
  String get warning => 'Warnung';

  @override
  String get normal => 'Normal';
}
