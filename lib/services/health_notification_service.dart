import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/heart_rate_analytics.dart';

class HealthNotificationService {
  static final HealthNotificationService _instance = HealthNotificationService._internal();
  factory HealthNotificationService() => _instance;
  HealthNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Navigate to health screen when notification is tapped
    debugPrint('Health notification tapped: ${response.payload}');
  }

  Future<void> showHealthInsight(HealthInsight insight) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'health_insights',
      'Health Insights',
      channelDescription: 'Weekly heart rate analysis and health insights',
      importance: _getImportance(insight.severity),
      priority: _getPriority(insight.severity),
      showWhen: true,
      enableVibration: insight.severity == InsightSeverity.alert,
      playSound: insight.severity == InsightSeverity.alert,
      styleInformation: BigTextStyleInformation(insight.description),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      insight.title,
      insight.description,
      details,
      payload: 'health_insight',
    );
  }

  Future<void> showHeartRateAnomaly(Anomaly anomaly) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'heart_rate_anomalies',
      'Heart Rate Alerts',
      channelDescription: 'Real-time heart rate anomaly alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: anomaly.type == AnomalyType.elevated || anomaly.type == AnomalyType.low,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      anomaly.timestamp.millisecondsSinceEpoch ~/ 1000,
      _getAnomalyTitle(anomaly.type),
      anomaly.message,
      details,
      payload: 'anomaly_${anomaly.type.name}',
    );
  }

  Future<void> showWeeklySummary(HeartRateAnalysis analysis) async {
    if (!_isInitialized) await initialize();

    final insights = _generateSummaryText(analysis);
    final shortInsights = insights.length > 100 ? insights.substring(0, 100) : insights;
    
    final androidDetails = AndroidNotificationDetails(
      'weekly_health_summary',
      'Weekly Health Summary',
      channelDescription: 'Weekly heart rate analysis summary',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      styleInformation: BigTextStyleInformation(insights),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1001, // Fixed ID for weekly summary
      'Weekly Heart Rate Summary',
      shortInsights,
      details,
      payload: 'weekly_summary',
    );
  }

  String _generateSummaryText(HeartRateAnalysis analysis) {
    final buffer = StringBuffer();
    buffer.writeln('Resting HR: ${analysis.restingBpm.toStringAsFixed(0)} BPM');
    buffer.writeln('Average HR: ${analysis.averageBpm.toStringAsFixed(0)} BPM');
    buffer.writeln('Range: ${analysis.minBpm.toStringAsFixed(0)}-${analysis.maxBpm.toStringAsFixed(0)} BPM');
    
    if (analysis.anomalies.isNotEmpty) {
      buffer.writeln('\n${analysis.anomalies.length} anomalies detected');
    }
    
    buffer.writeln('\nTrend: ${_getTrendText(analysis.trend)}');
    
    return buffer.toString();
  }

  String _getTrendText(HealthTrend trend) {
    switch (trend) {
      case HealthTrend.improving:
        return 'Improving 💪';
      case HealthTrend.concerning:
        return 'Needs attention ⚠️';
      case HealthTrend.stable:
        return 'Stable ✓';
    }
  }

  String _getAnomalyTitle(AnomalyType type) {
    switch (type) {
      case AnomalyType.elevated:
        return '⚠️ Elevated Heart Rate';
      case AnomalyType.low:
        return '⚠️ Low Heart Rate';
      case AnomalyType.irregular:
        return '⚠️ Irregular Heart Rate';
      case AnomalyType.trendUp:
        return '📈 Heart Rate Trending Up';
      case AnomalyType.trendDown:
        return '📉 Heart Rate Trending Down';
    }
  }

  Importance _getImportance(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.info:
        return Importance.defaultImportance;
      case InsightSeverity.warning:
        return Importance.high;
      case InsightSeverity.alert:
        return Importance.max;
    }
  }

  Priority _getPriority(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.info:
        return Priority.defaultPriority;
      case InsightSeverity.warning:
        return Priority.high;
      case InsightSeverity.alert:
        return Priority.max;
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
