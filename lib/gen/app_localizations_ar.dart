// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'لوحة الصحة الذكية';

  @override
  String get dashboardTitle => 'لوحة الصحة الذكية';

  @override
  String get pulseTooltip => 'النبض (ESP8266)';

  @override
  String get liveDashboardTooltip => 'لوحة مباشرة';

  @override
  String get healthDetailsTooltip => 'تفاصيل الصحة';

  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get heartRate => 'معدل ضربات القلب';

  @override
  String get oxygen => 'الأكسجين';

  @override
  String get spo2Level => 'مستوى SpO₂';

  @override
  String get wifiSignal => 'إشارة Wi‑Fi';

  @override
  String get battery => 'البطارية';

  @override
  String get solar => 'الطاقة الشمسية';

  @override
  String get charging => 'قيد الشحن';

  @override
  String get idle => 'خامل';

  @override
  String get harvestingEnergy => 'جمع الطاقة';

  @override
  String get noSolarInput => 'لا يوجد إدخال شمسي';

  @override
  String get waitingForData => 'بانتظار البيانات...';

  @override
  String get stable => 'مستقر';

  @override
  String get systemOnline => 'النظام متصل';

  @override
  String get systemOffline => 'النظام غير متصل';

  @override
  String get connectingToEsp32Firebase => 'جارٍ الاتصال بـ ESP32 / Firebase...';

  @override
  String get receivingRealtimeSensorData =>
      'استقبال بيانات المستشعر في الوقت الحقيقي';

  @override
  String get usingFallbackDummyData => 'استخدام بيانات احتياطية/تجريبية';

  @override
  String get cameraPreviewUnavailable => 'معاينة الكاميرا غير متاحة';

  @override
  String get glassesCamera => 'كاميرا النظارات';

  @override
  String get glassesEnv => 'بيئة النظارات';

  @override
  String get glassesLink => 'اتصال النظارات';

  @override
  String get tapToToggleDummy => 'اضغط للتبديل (تجريبي)';

  @override
  String get ambientTemperature => 'درجة الحرارة المحيطة';

  @override
  String get on => 'تشغيل';

  @override
  String get off => 'إيقاف';

  @override
  String get connected => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get smartGlassesStatus => 'حالة النظارات الذكية';

  @override
  String get autoSpeakAnalysis => 'نطق التحليل تلقائياً';

  @override
  String get speak => 'تحدث';

  @override
  String get stop => 'إيقاف';

  @override
  String get analyzeMyEnvironment => 'تحليل البيئة';

  @override
  String get analyzing => 'جارٍ التحليل...';

  @override
  String get environmentImageUploaded => 'تم رفع صورة البيئة للتحليل.';

  @override
  String failedToAnalyzeEnvironment(String error) {
    return 'فشل تحليل البيئة: $error';
  }

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get liveHealthDashboardTitle => 'لوحة الصحة المباشرة';

  @override
  String get refresh => 'تحديث';

  @override
  String get failedToLoadDashboard => 'فشل تحميل اللوحة';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get heartHealthTitle => 'صحة القلب';

  @override
  String get realTimeHeartRateTrend => 'اتجاه نبض القلب في الوقت الحقيقي';

  @override
  String get pulseRawTitle => 'النبض (ESP8266 Raw)';

  @override
  String get currentRaw => 'RAW الحالي';

  @override
  String get waitingForPulseData => 'بانتظار بيانات نبض ESP8266...';

  @override
  String get waitingForHeartRateData => 'بانتظار بيانات معدل ضربات القلب...';

  @override
  String get latestReading => 'آخر قراءة';

  @override
  String flags(String flags) {
    return 'الإشارات: $flags';
  }

  @override
  String get summary => 'الملخص';

  @override
  String historyLastN(int count) {
    return 'السجل (آخر $count)';
  }

  @override
  String get noReadingsYet => 'لا توجد قراءات بعد.';

  @override
  String get noRecentReadings => 'لا توجد قراءات حديثة.';

  @override
  String get critical => 'حرج';

  @override
  String get warning => 'تحذير';

  @override
  String get normal => 'طبيعي';
}
