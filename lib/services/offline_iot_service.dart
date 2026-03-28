import '../models/environment_analysis.dart';
import '../models/snapshots.dart';
import 'iot_service.dart';

class OfflineIoTService implements IoTService {
  @override
  Stream<SensorSnapshot> streamLatestSensorSnapshot({String deviceId = 'esp32cam-001'}) {
    return Stream<SensorSnapshot>.value(
      const SensorSnapshot(
        heartRateBpm: 0,
        oxygenPercent: 0,
        wifiSignal: 0,
        batteryLevel: 0,
        isChargingSolar: false,
        isOnline: false,
      ),
    );
  }

  @override
  Stream<GlassesSnapshot> streamLatestGlassesSnapshot({String deviceId = 'esp32cam-001'}) {
    return Stream<GlassesSnapshot>.value(
      const GlassesSnapshot(
        cameraOn: false,
        ambientTemperatureC: 0,
        connected: false,
      ),
    );
  }

  @override
  Stream<EnvironmentAnalysis> streamLatestEnvironmentAnalysis({String deviceId = 'esp32cam-001'}) {
    return Stream<EnvironmentAnalysis>.value(
      EnvironmentAnalysis(
        deviceId: deviceId,
        imageUrl: null,
        lighting: null,
        hazards: const [],
        summary: null,
        riskLevel: null,
      ),
    );
  }
}
