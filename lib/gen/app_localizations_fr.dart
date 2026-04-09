// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Tableau de Bord Santé';

  @override
  String get dashboardTitle => 'Tableau de Bord Santé';

  @override
  String get pulseTooltip => 'Pouls (ESP8266)';

  @override
  String get liveDashboardTooltip => 'Tableau en direct';

  @override
  String get healthDetailsTooltip => 'Détails santé';

  @override
  String get settingsTooltip => 'Paramètres';

  @override
  String get heartRate => 'Fréquence cardiaque';

  @override
  String get oxygen => 'Oxygène';

  @override
  String get spo2Level => 'Niveau SpO₂';

  @override
  String get wifiSignal => 'Signal Wi‑Fi';

  @override
  String get battery => 'Batterie';

  @override
  String get solar => 'Solaire';

  @override
  String get charging => 'En charge';

  @override
  String get idle => 'Inactif';

  @override
  String get harvestingEnergy => 'Collecte d\'énergie';

  @override
  String get noSolarInput => 'Pas d\'entrée solaire';

  @override
  String get waitingForData => 'En attente de données...';

  @override
  String get stable => 'Stable';

  @override
  String get systemOnline => 'Système en ligne';

  @override
  String get systemOffline => 'Système hors ligne';

  @override
  String get connectingToEsp32Firebase => 'Connexion à ESP32 / Firebase...';

  @override
  String get receivingRealtimeSensorData =>
      'Réception des données en temps réel';

  @override
  String get usingFallbackDummyData => 'Utilisation des données de secours';

  @override
  String get cameraPreviewUnavailable => 'Aperçu de la caméra indisponible';

  @override
  String get glassesCamera => 'Caméra des lunettes';

  @override
  String get glassesEnv => 'Environnement des lunettes';

  @override
  String get glassesLink => 'Lien des lunettes';

  @override
  String get tapToToggleDummy => 'Appuyez pour basculer (factice)';

  @override
  String get ambientTemperature => 'Température ambiante';

  @override
  String get on => 'Activé';

  @override
  String get off => 'Désactivé';

  @override
  String get connected => 'Connecté';

  @override
  String get offline => 'Hors ligne';

  @override
  String get smartGlassesStatus => 'Statut des lunettes intelligentes';

  @override
  String get autoSpeakAnalysis => 'Lire l\'analyse automatiquement';

  @override
  String get speak => 'Lire';

  @override
  String get stop => 'Arrêter';

  @override
  String get analyzeMyEnvironment => 'Analyser mon environnement';

  @override
  String get analyzing => 'Analyse...';

  @override
  String get environmentImageUploaded =>
      'Image envoyée pour analyse de l\'environnement.';

  @override
  String failedToAnalyzeEnvironment(String error) {
    return 'Échec de l\'analyse de l\'environnement : $error';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get liveHealthDashboardTitle => 'Tableau de Bord Santé en Direct';

  @override
  String get refresh => 'Actualiser';

  @override
  String get failedToLoadDashboard =>
      'Impossible de charger le tableau de bord';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get heartHealthTitle => 'Santé du cœur';

  @override
  String get realTimeHeartRateTrend =>
      'Tendance du rythme cardiaque en temps réel';

  @override
  String get pulseRawTitle => 'Pouls (ESP8266 Brut)';

  @override
  String get currentRaw => 'BRUT ACTUEL';

  @override
  String get waitingForPulseData =>
      'En attente des données de pouls ESP8266...';

  @override
  String get waitingForHeartRateData =>
      'En attente des données de fréquence cardiaque...';

  @override
  String get latestReading => 'Dernière mesure';

  @override
  String flags(String flags) {
    return 'Indicateurs : $flags';
  }

  @override
  String get summary => 'Résumé';

  @override
  String historyLastN(int count) {
    return 'Historique (derniers $count)';
  }

  @override
  String get noReadingsYet => 'Aucune mesure pour le moment.';

  @override
  String get noRecentReadings => 'Aucune mesure récente.';

  @override
  String get critical => 'Critique';

  @override
  String get warning => 'Avertissement';

  @override
  String get normal => 'Normal';
}
