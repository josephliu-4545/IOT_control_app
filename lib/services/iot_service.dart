import '../models/environment_analysis.dart';
import '../models/snapshots.dart';

abstract class IoTService {
  Stream<SensorSnapshot> streamLatestSensorSnapshot({
    String deviceId,
  });

  Stream<GlassesSnapshot> streamLatestGlassesSnapshot({
    String deviceId,
  });

  Stream<EnvironmentAnalysis> streamLatestEnvironmentAnalysis({
    String deviceId,
  });
}
