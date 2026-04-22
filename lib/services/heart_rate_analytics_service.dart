import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/heart_rate_analytics.dart';

class HeartRateAnalyticsService {
  static Database? _database;

  // Web-compatible in-memory storage fallback
  static final List<HeartRateReading> _memoryStore = [];
  static bool _useMemoryStore = false;
  
  // Web storage variables
  static final List<HeartRateReading> _webMemoryStore = [];
  static bool _useWebMemoryStore = false;
  
  // Baseline calculation constants
  static const int baselineDays = 7;
  static const int elevatedThreshold = 10;  // BPM above baseline
  static const int lowThreshold = 10;       // BPM below baseline
  static const double irregularThreshold = 0.3;  // 30% change = irregular

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'heart_rate_analytics.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE heart_rate_readings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bpm INTEGER NOT NULL,
            timestamp INTEGER NOT NULL,
            isResting INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_timestamp ON heart_rate_readings(timestamp)
        ''');
      },
    );
  }

  // Store a new heart rate reading
  Future<void> storeReading(int bpm, {bool isResting = false}) async {
    final reading = HeartRateReading(
      id: DateTime.now().millisecondsSinceEpoch,
      bpm: bpm,
      timestamp: DateTime.now(),
      isResting: isResting,
    );
    
    try {
      final db = await database;
      await db.insert('heart_rate_readings', reading.toMap());
      
      // Clean up old data
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      await db.delete(
        'heart_rate_readings',
        where: 'timestamp < ?',
        whereArgs: [cutoff.millisecondsSinceEpoch],
      );
    } catch (e) {
      // Fallback to memory for web
      _useMemoryStore = true;
      _memoryStore.add(reading);
      // Keep only last 1000 readings in memory
      if (_memoryStore.length > 1000) {
        _memoryStore.removeAt(0);
      }
    }
  }

  // Get readings for a specific date range
  Future<List<HeartRateReading>> getReadings({
    DateTime? start,
    DateTime? end,
  }) async {
    // Use memory store for web
    if (_useMemoryStore) {
      final startDate = start ?? DateTime.now().subtract(const Duration(days: 7));
      final endDate = end ?? DateTime.now();
      return _memoryStore.where((r) => 
        r.timestamp.isAfter(startDate) && r.timestamp.isBefore(endDate)
      ).toList();
    }
    
    // Use SQLite for mobile
    final db = await database;
    final startMs = (start ?? DateTime.now().subtract(const Duration(days: 7))).millisecondsSinceEpoch;
    final endMs = (end ?? DateTime.now()).millisecondsSinceEpoch;

    final maps = await db.query(
      'heart_rate_readings',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [startMs, endMs],
      orderBy: 'timestamp ASC',
    );

    return maps.map((m) => HeartRateReading.fromMap(m)).toList();
  }

  // Calculate baseline (average resting HR over baselineDays)
  Future<double> calculateBaseline() async {
    final readings = await getReadings(
      start: DateTime.now().subtract(const Duration(days: baselineDays)),
    );

    if (readings.isEmpty) return 70.0;  // Default baseline

    final restingReadings = readings.where((r) => r.isResting).toList();
    if (restingReadings.isEmpty) {
      // If no resting readings, use lowest 20% of readings as proxy
      final sorted = [...readings]..sort((a, b) => a.bpm.compareTo(b.bpm));
      final lowReadings = sorted.take((sorted.length * 0.2).ceil());
      return lowReadings.map((r) => r.bpm).reduce((a, b) => a + b) / lowReadings.length;
    }

    return restingReadings.map((r) => r.bpm).reduce((a, b) => a + b) / restingReadings.length;
  }

  // Generate analysis for the past week
  Future<HeartRateAnalysis> generateWeeklyAnalysis() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final readings = await getReadings(start: weekAgo, end: now);
    
    if (readings.isEmpty) {
      return HeartRateAnalysis(
        averageBpm: 0,
        restingBpm: 0,
        minBpm: 0,
        maxBpm: 0,
        hourlyTrend: List.filled(24, 0),
        anomalies: [],
        trend: HealthTrend.stable,
        periodStart: weekAgo,
        periodEnd: now,
      );
    }

    final bpms = readings.map((r) => r.bpm).toList();
    final average = bpms.reduce((a, b) => a + b) / bpms.length;
    final min = bpms.reduce((a, b) => a < b ? a : b).toDouble();
    final max = bpms.reduce((a, b) => a > b ? a : b).toDouble();

    final baseline = await calculateBaseline();
    final anomalies = _detectAnomalies(readings, baseline);
    final hourlyTrend = _calculateHourlyTrend(readings);
    final trend = _determineTrend(readings, baseline);

    return HeartRateAnalysis(
      averageBpm: average,
      restingBpm: baseline,
      minBpm: min,
      maxBpm: max,
      hourlyTrend: hourlyTrend,
      anomalies: anomalies,
      trend: trend,
      periodStart: weekAgo,
      periodEnd: now,
    );
  }

  // Detect anomalies based on baseline
  List<Anomaly> _detectAnomalies(List<HeartRateReading> readings, double baseline) {
    final anomalies = <Anomaly>[];
    
    if (readings.length < 2) return anomalies;

    for (int i = 0; i < readings.length; i++) {
      final reading = readings[i];
      final bpm = reading.bpm;

      // Check for elevated HR
      if (bpm > baseline + elevatedThreshold) {
        anomalies.add(Anomaly(
          timestamp: reading.timestamp,
          bpm: bpm,
          type: AnomalyType.elevated,
          message: 'Heart rate elevated: ${bpm.toStringAsFixed(0)} BPM (baseline: ${baseline.toStringAsFixed(0)})',
        ));
      }
      // Check for low HR
      else if (bpm < baseline - lowThreshold && bpm < 50) {
        anomalies.add(Anomaly(
          timestamp: reading.timestamp,
          bpm: bpm,
          type: AnomalyType.low,
          message: 'Heart rate unusually low: ${bpm.toStringAsFixed(0)} BPM',
        ));
      }

      // Check for irregular patterns (sudden change > 30%)
      if (i > 0) {
        final prevBpm = readings[i - 1].bpm;
        final change = (bpm - prevBpm).abs() / prevBpm;
        
        if (change > irregularThreshold) {
          anomalies.add(Anomaly(
            timestamp: reading.timestamp,
            bpm: bpm,
            type: AnomalyType.irregular,
            message: 'Irregular heart rate detected: ${bpm.toStringAsFixed(0)} BPM (sudden ${change > 0 ? 'increase' : 'decrease'})',
          ));
        }
      }
    }

    // Check for weekly trends
    final firstHalf = readings.take(readings.length ~/ 2).toList();
    final secondHalf = readings.skip(readings.length ~/ 2).toList();
    
    if (firstHalf.isNotEmpty && secondHalf.isNotEmpty) {
      final firstAvg = firstHalf.map((r) => r.bpm).reduce((a, b) => a + b) / firstHalf.length;
      final secondAvg = secondHalf.map((r) => r.bpm).reduce((a, b) => a + b) / secondHalf.length;
      
      final trendChange = (secondAvg - firstAvg) / firstAvg;
      
      if (trendChange > 0.15) {  // 15% increase
        anomalies.add(Anomaly(
          timestamp: readings.last.timestamp,
          bpm: secondAvg.round(),
          type: AnomalyType.trendUp,
          message: 'Weekly trend: Heart rate increasing (${(trendChange * 100).toStringAsFixed(1)}% higher than early week)',
        ));
      } else if (trendChange < -0.15) {  // 15% decrease
        anomalies.add(Anomaly(
          timestamp: readings.last.timestamp,
          bpm: secondAvg.round(),
          type: AnomalyType.trendDown,
          message: 'Weekly trend: Heart rate decreasing (${(trendChange * 100).toStringAsFixed(1)}% lower than early week)',
        ));
      }
    }

    return anomalies;
  }

  // Calculate hourly average trend
  List<int> _calculateHourlyTrend(List<HeartRateReading> readings) {
    final hourlyData = List<List<int>>.generate(24, (_) => []);
    
    for (final reading in readings) {
      final hour = reading.timestamp.hour;
      hourlyData[hour].add(reading.bpm);
    }

    return hourlyData.map((hourReadings) {
      if (hourReadings.isEmpty) return 0;
      return (hourReadings.reduce((a, b) => a + b) / hourReadings.length).round();
    }).toList();
  }

  // Determine overall health trend
  HealthTrend _determineTrend(List<HeartRateReading> readings, double baseline) {
    if (readings.length < 20) return HealthTrend.stable;

    final recent = readings.skip(readings.length - 20).toList();
    final recentAvg = recent.map((r) => r.bpm).reduce((a, b) => a + b) / recent.length;
    
    final elevatedCount = recent.where((r) => r.bpm > baseline + elevatedThreshold).length;
    final concerningRatio = elevatedCount / recent.length;

    if (concerningRatio > 0.3) return HealthTrend.concerning;
    if (recentAvg < baseline - 5) return HealthTrend.improving;  // Lower resting = better fitness
    
    return HealthTrend.stable;
  }

  // Generate health insights from analysis
  List<HealthInsight> generateInsights(HeartRateAnalysis analysis) {
    final insights = <HealthInsight>[];

    if (analysis.anomalies.isEmpty) {
      insights.add(HealthInsight(
        title: 'Heart Rate Normal',
        description: 'Your heart rate has been stable over the past week.',
        severity: InsightSeverity.info,
        generatedAt: DateTime.now(),
      ));
      return insights;
    }

    // Group anomalies by type
    final elevatedCount = analysis.anomalies.where((a) => a.type == AnomalyType.elevated).length;
    final irregularCount = analysis.anomalies.where((a) => a.type == AnomalyType.irregular).length;
    final hasTrendUp = analysis.anomalies.any((a) => a.type == AnomalyType.trendUp);

    if (elevatedCount > 5) {
      insights.add(HealthInsight(
        title: 'Frequent Elevated Heart Rate',
        description: 'Your heart rate was elevated ${elevatedCount} times this week. This may indicate stress, poor sleep, or illness.',
        severity: InsightSeverity.warning,
        generatedAt: DateTime.now(),
      ));
    }

    if (irregularCount > 3) {
      insights.add(HealthInsight(
        title: 'Irregular Heart Rate Pattern',
        description: 'Multiple irregular heart rate spikes detected. Consider consulting a healthcare provider.',
        severity: InsightSeverity.alert,
        generatedAt: DateTime.now(),
      ));
    }

    if (hasTrendUp) {
      insights.add(HealthInsight(
        title: 'Rising Heart Rate Trend',
        description: 'Your average heart rate is trending upward. Monitor for fever, stress, or dehydration.',
        severity: InsightSeverity.warning,
        generatedAt: DateTime.now(),
      ));
    }

    return insights;
  }

  // Generate fake demo data for a week (for presentations)
  Future<void> generateDemoData() async {
    final random = Random();
    final now = DateTime.now();
    
    // Generate 7 days of data, every 30 minutes
    for (int day = 0; day < 7; day++) {
      for (int hour = 0; hour < 24; hour++) {
        for (int minute = 0; minute < 60; minute += 30) {
          final timestamp = now.subtract(Duration(days: day, hours: hour, minutes: minute));
          
          // Simulate realistic heart rate patterns
          int baseBpm;
          if (hour >= 0 && hour < 6) {
            baseBpm = 60 + random.nextInt(15); // Sleep: 60-75 BPM
          } else if (hour >= 6 && hour < 9) {
            baseBpm = 70 + random.nextInt(20); // Morning: 70-90 BPM
          } else if (hour >= 9 && hour < 17) {
            baseBpm = 75 + random.nextInt(25); // Active: 75-100 BPM
          } else {
            baseBpm = 68 + random.nextInt(18); // Evening: 68-86 BPM
          }
          
          // Add occasional spikes (exercise/stress)
          if (random.nextInt(20) == 0) {
            baseBpm += 30 + random.nextInt(40); // Spike to 110-140
          }
          
          // Create reading
          final reading = HeartRateReading(
            id: timestamp.millisecondsSinceEpoch,
            bpm: baseBpm.clamp(50, 160),
            timestamp: timestamp,
            isResting: baseBpm < 85 && hour >= 0 && hour < 6,
          );
          
          // Store in memory (web) or database (mobile)
          try {
            final db = await database;
            await db.insert('heart_rate_readings', reading.toMap());
          } catch (e) {
            _useMemoryStore = true;
            _memoryStore.add(reading);
          }
        }
      }
    }
    
    // Clean up excess memory store
    if (_memoryStore.length > 1000) {
      _memoryStore.removeRange(0, _memoryStore.length - 1000);
    }
  }
}
