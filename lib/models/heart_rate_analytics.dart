class HeartRateReading {
  final int bpm;
  final DateTime timestamp;
  final bool isResting;  // Calculated based on activity context

  HeartRateReading({
    required this.bpm,
    required this.timestamp,
    this.isResting = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'bpm': bpm,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isResting': isResting ? 1 : 0,
    };
  }

  factory HeartRateReading.fromMap(Map<String, dynamic> map) {
    return HeartRateReading(
      bpm: map['bpm'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isResting: map['isResting'] == 1,
    );
  }
}

class HeartRateAnalysis {
  final double averageBpm;
  final double restingBpm;
  final double minBpm;
  final double maxBpm;
  final List<int> hourlyTrend;  // 24-hour average BPM
  final List<Anomaly> anomalies;
  final HealthTrend trend;
  final DateTime periodStart;
  final DateTime periodEnd;

  HeartRateAnalysis({
    required this.averageBpm,
    required this.restingBpm,
    required this.minBpm,
    required this.maxBpm,
    required this.hourlyTrend,
    required this.anomalies,
    required this.trend,
    required this.periodStart,
    required this.periodEnd,
  });
}

class Anomaly {
  final DateTime timestamp;
  final int bpm;
  final AnomalyType type;
  final String message;

  Anomaly({
    required this.timestamp,
    required this.bpm,
    required this.type,
    required this.message,
  });
}

enum AnomalyType {
  elevated,    // Above normal range
  low,         // Below normal range
  irregular,   // Sudden spike/drop
  trendUp,     // Increasing trend
  trendDown,   // Decreasing trend
}

enum HealthTrend {
  stable,
  improving,
  concerning,
}

class HealthInsight {
  final String title;
  final String description;
  final InsightSeverity severity;
  final DateTime generatedAt;

  HealthInsight({
    required this.title,
    required this.description,
    required this.severity,
    required this.generatedAt,
  });
}

enum InsightSeverity {
  info,
  warning,
  alert,
}
