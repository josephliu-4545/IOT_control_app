// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'स्मार्ट हेल्थ डैशबोर्ड';

  @override
  String get dashboardTitle => 'स्मार्ट हेल्थ डैशबोर्ड';

  @override
  String get pulseTooltip => 'पल्स (ESP8266)';

  @override
  String get liveDashboardTooltip => 'लाइव डैशबोर्ड';

  @override
  String get healthDetailsTooltip => 'स्वास्थ्य विवरण';

  @override
  String get settingsTooltip => 'सेटिंग्स';

  @override
  String get heartRate => 'हृदय गति';

  @override
  String get oxygen => 'ऑक्सीजन';

  @override
  String get spo2Level => 'SpO₂ स्तर';

  @override
  String get wifiSignal => 'Wi‑Fi सिग्नल';

  @override
  String get battery => 'बैटरी';

  @override
  String get solar => 'सोलर';

  @override
  String get charging => 'चार्ज हो रहा है';

  @override
  String get idle => 'निष्क्रिय';

  @override
  String get harvestingEnergy => 'ऊर्जा एकत्रित हो रही है';

  @override
  String get noSolarInput => 'कोई सोलर इनपुट नहीं';

  @override
  String get waitingForData => 'डेटा की प्रतीक्षा...';

  @override
  String get stable => 'स्थिर';

  @override
  String get systemOnline => 'सिस्टम ऑनलाइन';

  @override
  String get systemOffline => 'सिस्टम ऑफलाइन';

  @override
  String get connectingToEsp32Firebase =>
      'ESP32 / Firebase से कनेक्ट हो रहा है...';

  @override
  String get receivingRealtimeSensorData =>
      'रीयल-टाइम सेंसर डेटा प्राप्त हो रहा है';

  @override
  String get usingFallbackDummyData => 'बैकअप/डमी डेटा उपयोग हो रहा है';

  @override
  String get cameraPreviewUnavailable => 'कैमरा प्रीव्यू उपलब्ध नहीं';

  @override
  String get glassesCamera => 'ग्लासेस कैमरा';

  @override
  String get glassesEnv => 'ग्लासेस वातावरण';

  @override
  String get glassesLink => 'ग्लासेस लिंक';

  @override
  String get tapToToggleDummy => 'टैप करके बदलें (डमी)';

  @override
  String get ambientTemperature => 'पर्यावरण तापमान';

  @override
  String get on => 'चालू';

  @override
  String get off => 'बंद';

  @override
  String get connected => 'कनेक्टेड';

  @override
  String get offline => 'ऑफलाइन';

  @override
  String get smartGlassesStatus => 'स्मार्ट ग्लासेस स्थिति';

  @override
  String get autoSpeakAnalysis => 'विश्लेषण स्वतः बोलें';

  @override
  String get speak => 'बोलें';

  @override
  String get stop => 'रोकें';

  @override
  String get analyzeMyEnvironment => 'मेरा वातावरण विश्लेषित करें';

  @override
  String get analyzing => 'विश्लेषण हो रहा है...';

  @override
  String get environmentImageUploaded =>
      'वातावरण चित्र विश्लेषण के लिए अपलोड किया गया।';

  @override
  String failedToAnalyzeEnvironment(String error) {
    return 'वातावरण विश्लेषण विफल: $error';
  }

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get liveHealthDashboardTitle => 'लाइव हेल्थ डैशबोर्ड';

  @override
  String get refresh => 'रिफ्रेश';

  @override
  String get failedToLoadDashboard => 'डैशबोर्ड लोड नहीं हो सका';

  @override
  String get tryAgain => 'फिर से प्रयास करें';

  @override
  String get heartHealthTitle => 'हृदय स्वास्थ्य';

  @override
  String get realTimeHeartRateTrend => 'रीयल-टाइम हार्ट रेट ट्रेंड';

  @override
  String get pulseRawTitle => 'पल्स (ESP8266 Raw)';

  @override
  String get currentRaw => 'वर्तमान RAW';

  @override
  String get waitingForPulseData => 'ESP8266 पल्स डेटा की प्रतीक्षा...';

  @override
  String get waitingForHeartRateData => 'हृदय गति डेटा की प्रतीक्षा...';

  @override
  String get latestReading => 'नवीनतम रीडिंग';

  @override
  String flags(String flags) {
    return 'फ़्लैग्स: $flags';
  }

  @override
  String get summary => 'सारांश';

  @override
  String historyLastN(int count) {
    return 'इतिहास (पिछले $count)';
  }

  @override
  String get noReadingsYet => 'अभी तक कोई रीडिंग नहीं।';

  @override
  String get noRecentReadings => 'कोई हाल की रीडिंग नहीं।';

  @override
  String get critical => 'गंभीर';

  @override
  String get warning => 'चेतावनी';

  @override
  String get normal => 'सामान्य';
}
