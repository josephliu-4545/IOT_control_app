// lib/services/blynk_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';

/// Immutable snapshot of all sensor values at a given moment.
class SensorSnapshot {
  final int heartRateBpm;
  final int oxygenPercent;
  final int wifiSignal; // 0–100 (%)
  final int batteryLevel; // 0–100 (%)
  final bool isChargingSolar;
  final bool isOnline;

  const SensorSnapshot({
    required this.heartRateBpm,
    required this.oxygenPercent,
    required this.wifiSignal,
    required this.batteryLevel,
    required this.isChargingSolar,
    required this.isOnline,
  });

  SensorSnapshot copyWith({
    int? heartRateBpm,
    int? oxygenPercent,
    int? wifiSignal,
    int? batteryLevel,
    bool? isChargingSolar,
    bool? isOnline,
  }) {
    return SensorSnapshot(
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      oxygenPercent: oxygenPercent ?? this.oxygenPercent,
      wifiSignal: wifiSignal ?? this.wifiSignal,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isChargingSolar: isChargingSolar ?? this.isChargingSolar,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class BlynkService {
  final String authToken;
  final bool useDummyData;
  final Random _random = Random();

  BlynkService({
    String? authToken,
    bool? useDummyData,
  })  : authToken = authToken ?? BlynkConfig.authToken,
        useDummyData = useDummyData ?? BlynkConfig.useDummyData;

  /// Public API: fetch one combined snapshot of all values.
  Future<SensorSnapshot> fetchSensorSnapshot() async {
    if (useDummyData) {
      return _generateDummySnapshot();
    }

    try {
      // You can request multiple pins at once from Blynk Cloud, e.g.:
      // GET /get?token=YOUR_TOKEN&V0&V1&V2&V3
      final uri = Uri.parse(
        '${BlynkConfig.baseUrl}/get'
        '?token=$authToken'
        '&${BlynkConfig.pinHeartRate}'
        '&${BlynkConfig.pinOxygen}'
        '&${BlynkConfig.pinWifi}'
        '&${BlynkConfig.pinBattery}',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        return _generateDummySnapshot(isOnline: false);
      }

      final List<dynamic> values = jsonDecode(response.body);

      int heartRate = _parseInt(values.elementAtOrNull(0), fallback: 75);
      int oxygen = _parseInt(values.elementAtOrNull(1), fallback: 98);
      int wifi = _parseInt(values.elementAtOrNull(2), fallback: 80);
      int battery = _parseInt(values.elementAtOrNull(3), fallback: 70);

      // Simple heuristic: charging if wifi is strong and battery < 100 (just an example).
      final bool chargingSolar = wifi > 60 && battery < 100;

      return SensorSnapshot(
        heartRateBpm: heartRate,
        oxygenPercent: oxygen,
        wifiSignal: wifi.clamp(0, 100),
        batteryLevel: battery.clamp(0, 100),
        isChargingSolar: chargingSolar,
        isOnline: true,
      );
    } on TimeoutException {
      return _generateDummySnapshot(isOnline: false);
    } catch (_) {
      return _generateDummySnapshot(isOnline: false);
    }
  }

  int _parseInt(dynamic value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  SensorSnapshot _generateDummySnapshot({bool isOnline = true}) {
    final int baseHeart = 72;
    final int heartRate = baseHeart + _random.nextInt(10) - 5;
    final int oxygen = 96 + _random.nextInt(3);
    final int wifi = 60 + _random.nextInt(40);
    final int battery = 40 + _random.nextInt(60);
    final bool charging = _random.nextBool();

    return SensorSnapshot(
      heartRateBpm: heartRate,
      oxygenPercent: oxygen,
      wifiSignal: wifi.clamp(0, 100),
      batteryLevel: battery.clamp(0, 100),
      isChargingSolar: charging,
      isOnline: isOnline,
    );
  }
}

extension _SafeElementAt<E> on List<E> {
  E? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}