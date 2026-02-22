// lib/services/firebase_iot_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/environment_analysis.dart';
import '../models/snapshots.dart';

class FirebaseIoTService {
  final FirebaseFirestore _firestore;

  FirebaseIoTService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<SensorSnapshot> streamLatestSensorSnapshot({
    String deviceId = 'esp32cam-001',
  }) {
    return _firestore
        .collection('heart_rate_analysis')
        .where('deviceId', isEqualTo: deviceId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        return const SensorSnapshot(
          heartRateBpm: 0,
          oxygenPercent: 0,
          wifiSignal: 0,
          batteryLevel: 0,
          isChargingSolar: false,
          isOnline: false,
        );
      }

      final data = snap.docs.first.data();

      final bpm = (data['bpm'] as num?)?.toInt() ?? 0;
      final spo2 = (data['spo2'] as num?)?.toInt() ?? 0;

      return SensorSnapshot(
        heartRateBpm: bpm,
        oxygenPercent: spo2,
        wifiSignal: 0,
        batteryLevel: 0,
        isChargingSolar: false,
        isOnline: true,
      );
    });
  }

  Stream<GlassesSnapshot> streamLatestGlassesSnapshot({
    String deviceId = 'esp32cam-001',
  }) {
    return _firestore
        .collection('glasses_state')
        .where('deviceId', isEqualTo: deviceId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        return const GlassesSnapshot(
          cameraOn: false,
          ambientTemperatureC: 0,
          connected: false,
        );
      }

      final data = snap.docs.first.data();

      return GlassesSnapshot(
        cameraOn: (data['cameraOn'] as bool?) ?? false,
        ambientTemperatureC: (data['ambientTemperatureC'] as num?)?.toDouble() ??
            0,
        connected: (data['connected'] as bool?) ?? false,
      );
    });
  }

  Stream<EnvironmentAnalysis> streamLatestEnvironmentAnalysis({
    String deviceId = 'esp32cam-001',
  }) {
    return _firestore
        .collection('environment_analysis')
        .where('deviceId', isEqualTo: deviceId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        return EnvironmentAnalysis(
          deviceId: deviceId,
          imageUrl: null,
          lighting: null,
          hazards: const [],
          summary: null,
          riskLevel: null,
        );
      }

      final data = snap.docs.first.data();
      return EnvironmentAnalysis.fromFirestore(data: data);
    });
  }
}
