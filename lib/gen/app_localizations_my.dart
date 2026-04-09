// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Burmese (`my`).
class AppLocalizationsMy extends AppLocalizations {
  AppLocalizationsMy([String locale = 'my']) : super(locale);

  @override
  String get appTitle => 'စမတ် ကျန်းမာရေး ဒက်ရှ်ဘုတ်';

  @override
  String get dashboardTitle => 'စမတ် ကျန်းမာရေး ဒက်ရှ်ဘုတ်';

  @override
  String get pulseTooltip => 'Pulse (ESP8266)';

  @override
  String get liveDashboardTooltip => 'တိုက်ရိုက်ထုတ်လွှ Dashboard Tooltip';

  @override
  String get healthDetailsTooltip => 'ကျန်းမာရေးအသေးစိတ်';

  @override
  String get settingsTooltip => 'ဆက်တင်များ';

  @override
  String get heartRate => 'နှလုံးခုန်နှုန်း';

  @override
  String get oxygen => 'အောက်ဆီဂျင်';

  @override
  String get spo2Level => 'SpO₂ အဆင့်';

  @override
  String get wifiSignal => 'Wi-Fi Signal';

  @override
  String get battery => 'ဘက်ထရီ';

  @override
  String get solar => 'နေရောင်ခြည်';

  @override
  String get charging => 'အားသွင်း';

  @override
  String get idle => 'Idle';

  @override
  String get harvestingEnergy => 'စွမ်းအင်ရိတ်သိမ်း';

  @override
  String get noSolarInput => 'ဆိုလာထည့်သွင်းမှုမရှိ';

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
  String get cameraPreviewUnavailable => 'ကင်မရာ အစမ်းကြည့်ရှုခြင်း မရနိုင်ပါ';

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
  String get autoSpeakAnalysis =>
      'ခွဲခြမ်းစိတ်ဖြာချက်ကို အလိုအလျောက် ဖတ်ကြားရန်';

  @override
  String get speak => 'ဖတ်ကြား';

  @override
  String get stop => 'ရပ်မည်';

  @override
  String get analyzeMyEnvironment => 'ပတ်ဝန်းကျင်ကို ခွဲခြမ်းစိတ်ဖြာရန်';

  @override
  String get analyzing => 'ခွဲခြမ်းစိတ်ဖြာနေသည်...';

  @override
  String get environmentImageUploaded =>
      'ပတ်ဝန်းကျင်ပုံကို ခွဲခြမ်းစိတ်ဖြာရန် ပို့ပြီးပါပြီ။';

  @override
  String failedToAnalyzeEnvironment(String error) {
    return 'ပတ်ဝန်းကျင်ကို ခွဲခြမ်းစိတ်ဖြာ၍ မရပါ: $error';
  }

  @override
  String get settingsTitle => 'ဆက်တင်များ';

  @override
  String get language => 'ဘာသာစကား';

  @override
  String get liveHealthDashboardTitle => 'တိုက်ရိုက် ကျန်းမာရေး ဒက်ရှ်ဘုတ်';

  @override
  String get refresh => 'ပြန်လည်ရယူ';

  @override
  String get failedToLoadDashboard => 'ဒက်ရှ်ဘုတ်ကို ဖွင့်၍ မရပါ';

  @override
  String get tryAgain => 'ထပ်ကြိုးစား';

  @override
  String get heartHealthTitle => 'နှလုံးကျန်းမာရေး';

  @override
  String get realTimeHeartRateTrend =>
      'အချိန်နှင့်တပြေးညီ နှလုံးခုန်နှုန်း လမ်းကြောင်း';

  @override
  String get pulseRawTitle => 'Pulse (ESP8266 Raw)';

  @override
  String get currentRaw => 'လက်ရှိ RAW';

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
