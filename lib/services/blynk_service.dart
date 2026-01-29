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

/// Snapshot of smart glasses state (separate from wristband vitals).
class GlassesSnapshot {
  final bool cameraOn;
  final double ambientTemperatureC;
  final bool connected;

  const GlassesSnapshot({
    required this.cameraOn,
    required this.ambientTemperatureC,
    required this.connected,
  });
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

  /// Fetch smart glasses state (camera, environment, connection).
  ///
  /// When [useDummyData] is true, this returns simulated but realistic data.
  Future<GlassesSnapshot> fetchGlassesSnapshot() async {
    if (useDummyData) {
      return _generateDummyGlassesSnapshot();
    }

    try {
      // GET /get?token=YOUR_TOKEN&V10&V11&V12
      final uri = Uri.parse(
        '${BlynkConfig.baseUrl}/get'
        '?token=$authToken'
        '&${BlynkConfig.pinGlassesCamera}'
        '&${BlynkConfig.pinGlassesTemperature}'
        '&${BlynkConfig.pinGlassesLink}',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        return _generateDummyGlassesSnapshot();
      }

      final List<dynamic> values = jsonDecode(response.body);

      final int cameraRaw = _parseInt(values.elementAtOrNull(0), fallback: 0);
      final bool cameraOn = cameraRaw != 0;

      // Temperature may be reported as int or double; treat as double.
      final dynamic tempRaw = values.elementAtOrNull(1);
      final double temperature = _parseDouble(tempRaw, fallback: 26.5);

      final int linkRaw = _parseInt(values.elementAtOrNull(2), fallback: 1);
      final bool connected = linkRaw != 0;

      return GlassesSnapshot(
        cameraOn: cameraOn,
        ambientTemperatureC: temperature,
        connected: connected,
      );
    } on TimeoutException {
      return _generateDummyGlassesSnapshot();
    } catch (_) {
      return _generateDummyGlassesSnapshot();
    }
  }

  /// Toggle smart glasses camera via Blynk.
  ///
  /// In dummy mode, this only simulates success without calling the API.
  Future<void> setGlassesCamera(bool on) async {
    if (useDummyData) {
      // No-op in dummy mode; view models can still update local UI state.
      return;
    }

    final value = on ? '1' : '0';

    final uri = Uri.parse(
      '${BlynkConfig.baseUrl}/update'
      '?token=$authToken'
      '&${BlynkConfig.pinGlassesCamera}=$value',
    );

    try {
      await http.get(uri).timeout(const Duration(seconds: 5));
    } on TimeoutException {
      // For now, we silently ignore failures; callers may choose to refetch state.
    } catch (_) {
      // Swallow network errors for now; could be logged in a real app.
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

  double _parseDouble(dynamic value, {required double fallback}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? fallback;
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

  GlassesSnapshot _generateDummyGlassesSnapshot() {
    // Simulate realistic ambient temperature (e.g. 24–32 °C).
    final double temp = 24 + _random.nextDouble() * 8;
    // Simulate mostly-connected link with occasional drops.
    final bool connected = _random.nextInt(10) > 1;
    // Camera is off by default, occasionally on.
    final bool cameraOn = _random.nextInt(10) == 0;

    return GlassesSnapshot(
      cameraOn: cameraOn,
      ambientTemperatureC: temp,
      connected: connected,
    );
  }
}

extension _SafeElementAt<E> on List<E> {
  E? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}