// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Panel de Salud Inteligente';

  @override
  String get dashboardTitle => 'Panel de Salud Inteligente';

  @override
  String get pulseTooltip => 'Pulso (ESP8266)';

  @override
  String get liveDashboardTooltip => 'Panel en vivo';

  @override
  String get healthDetailsTooltip => 'Detalles de salud';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get heartRate => 'Frecuencia cardíaca';

  @override
  String get oxygen => 'Oxígeno';

  @override
  String get spo2Level => 'Nivel de SpO₂';

  @override
  String get wifiSignal => 'Señal Wi‑Fi';

  @override
  String get battery => 'Batería';

  @override
  String get solar => 'Solar';

  @override
  String get charging => 'Cargando';

  @override
  String get idle => 'Inactivo';

  @override
  String get harvestingEnergy => 'Recolectando energía';

  @override
  String get noSolarInput => 'Sin entrada solar';

  @override
  String get waitingForData => 'Esperando datos...';

  @override
  String get stable => 'Estable';

  @override
  String get systemOnline => 'Sistema en línea';

  @override
  String get systemOffline => 'Sistema fuera de línea';

  @override
  String get connectingToEsp32Firebase => 'Conectando a ESP32 / Firebase...';

  @override
  String get receivingRealtimeSensorData => 'Recibiendo datos en tiempo real';

  @override
  String get usingFallbackDummyData => 'Usando datos de respaldo';

  @override
  String get cameraPreviewUnavailable => 'Vista previa de cámara no disponible';

  @override
  String get glassesCamera => 'Cámara de gafas';

  @override
  String get glassesEnv => 'Entorno de gafas';

  @override
  String get glassesLink => 'Enlace de gafas';

  @override
  String get tapToToggleDummy => 'Toca para alternar (simulado)';

  @override
  String get ambientTemperature => 'Temperatura ambiente';

  @override
  String get on => 'Encendido';

  @override
  String get off => 'Apagado';

  @override
  String get connected => 'Conectado';

  @override
  String get offline => 'Sin conexión';

  @override
  String get smartGlassesStatus => 'Estado de gafas inteligentes';

  @override
  String get autoSpeakAnalysis => 'Hablar análisis automáticamente';

  @override
  String get speak => 'Hablar';

  @override
  String get stop => 'Detener';

  @override
  String get analyzeMyEnvironment => 'Analizar mi entorno';

  @override
  String get analyzing => 'Analizando...';

  @override
  String get environmentImageUploaded =>
      'Imagen enviada para análisis del entorno.';

  @override
  String failedToAnalyzeEnvironment(String error) {
    return 'No se pudo analizar el entorno: $error';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get liveHealthDashboardTitle => 'Panel de Salud en Vivo';

  @override
  String get refresh => 'Actualizar';

  @override
  String get failedToLoadDashboard => 'No se pudo cargar el panel';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get heartHealthTitle => 'Salud del corazón';

  @override
  String get realTimeHeartRateTrend =>
      'Tendencia de ritmo cardíaco en tiempo real';

  @override
  String get pulseRawTitle => 'Pulso (ESP8266 Raw)';

  @override
  String get currentRaw => 'RAW ACTUAL';

  @override
  String get waitingForPulseData => 'Esperando datos de pulso de ESP8266...';

  @override
  String get waitingForHeartRateData =>
      'Esperando datos de frecuencia cardíaca...';

  @override
  String get latestReading => 'Última lectura';

  @override
  String flags(String flags) {
    return 'Indicadores: $flags';
  }

  @override
  String get summary => 'Resumen';

  @override
  String historyLastN(int count) {
    return 'Historial (últimos $count)';
  }

  @override
  String get noReadingsYet => 'Aún no hay lecturas.';

  @override
  String get noRecentReadings => 'No hay lecturas recientes.';

  @override
  String get critical => 'Crítico';

  @override
  String get warning => 'Advertencia';

  @override
  String get normal => 'Normal';
}
