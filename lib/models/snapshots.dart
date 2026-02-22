// lib/models/snapshots.dart

/// Immutable snapshot of all sensor values at a given moment.
class SensorSnapshot {
  final int heartRateBpm;
  final int oxygenPercent;
  final int wifiSignal; // 0–100 (%).
  final int batteryLevel; // 0–100 (%).
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
