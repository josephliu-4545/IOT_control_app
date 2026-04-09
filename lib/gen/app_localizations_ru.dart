// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Умная Панель Здоровья';

  @override
  String get dashboardTitle => 'Умная Панель Здоровья';

  @override
  String get pulseTooltip => 'Пульс (ESP8266)';

  @override
  String get liveDashboardTooltip => 'Панель в реальном времени';

  @override
  String get healthDetailsTooltip => 'Детали здоровья';

  @override
  String get settingsTooltip => 'Настройки';

  @override
  String get heartRate => 'Пульс';

  @override
  String get oxygen => 'Кислород';

  @override
  String get spo2Level => 'Уровень SpO₂';

  @override
  String get wifiSignal => 'Сигнал Wi‑Fi';

  @override
  String get battery => 'Батарея';

  @override
  String get solar => 'Солнечная';

  @override
  String get charging => 'Зарядка';

  @override
  String get idle => 'Ожидание';

  @override
  String get harvestingEnergy => 'Сбор энергии';

  @override
  String get noSolarInput => 'Нет солнечного ввода';

  @override
  String get waitingForData => 'Ожидание данных...';

  @override
  String get stable => 'Стабильно';

  @override
  String get systemOnline => 'Система онлайн';

  @override
  String get systemOffline => 'Система офлайн';

  @override
  String get connectingToEsp32Firebase => 'Подключение к ESP32 / Firebase...';

  @override
  String get receivingRealtimeSensorData =>
      'Получение данных в реальном времени';

  @override
  String get usingFallbackDummyData => 'Используются резервные/тестовые данные';

  @override
  String get cameraPreviewUnavailable => 'Предпросмотр камеры недоступен';

  @override
  String get glassesCamera => 'Камера очков';

  @override
  String get glassesEnv => 'Среда очков';

  @override
  String get glassesLink => 'Связь очков';

  @override
  String get tapToToggleDummy => 'Нажмите, чтобы переключить (заглушка)';

  @override
  String get ambientTemperature => 'Температура окружающей среды';

  @override
  String get on => 'Вкл';

  @override
  String get off => 'Выкл';

  @override
  String get connected => 'Подключено';

  @override
  String get offline => 'Офлайн';

  @override
  String get smartGlassesStatus => 'Статус умных очков';

  @override
  String get autoSpeakAnalysis => 'Автоматически озвучивать анализ';

  @override
  String get speak => 'Озвучить';

  @override
  String get stop => 'Стоп';

  @override
  String get analyzeMyEnvironment => 'Проанализировать окружение';

  @override
  String get analyzing => 'Анализ...';

  @override
  String get environmentImageUploaded =>
      'Изображение окружения отправлено на анализ.';

  @override
  String failedToAnalyzeEnvironment(String error) {
    return 'Не удалось проанализировать окружение: $error';
  }

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get language => 'Язык';

  @override
  String get liveHealthDashboardTitle => 'Живая Панель Здоровья';

  @override
  String get refresh => 'Обновить';

  @override
  String get failedToLoadDashboard => 'Не удалось загрузить панель';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get heartHealthTitle => 'Здоровье сердца';

  @override
  String get realTimeHeartRateTrend => 'Тренд пульса в реальном времени';

  @override
  String get pulseRawTitle => 'Пульс (ESP8266 Raw)';

  @override
  String get currentRaw => 'ТЕКУЩИЙ RAW';

  @override
  String get waitingForPulseData => 'Ожидание данных пульса ESP8266...';

  @override
  String get waitingForHeartRateData => 'Ожидание данных пульса...';

  @override
  String get latestReading => 'Последнее измерение';

  @override
  String flags(String flags) {
    return 'Флаги: $flags';
  }

  @override
  String get summary => 'Сводка';

  @override
  String historyLastN(int count) {
    return 'История (последние $count)';
  }

  @override
  String get noReadingsYet => 'Пока нет измерений.';

  @override
  String get noRecentReadings => 'Нет недавних измерений.';

  @override
  String get critical => 'Критично';

  @override
  String get warning => 'Предупреждение';

  @override
  String get normal => 'Норма';
}
