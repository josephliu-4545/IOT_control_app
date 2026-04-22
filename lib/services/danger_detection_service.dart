import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../config/api_config.dart';
import 'esp32_cam_service.dart';

enum DangerLevel { none, low, medium, high }

class DetectedObject {
  final String label;
  final double confidence;
  final DangerLevel dangerLevel;
  final DateTime timestamp;
  final Uint8List? imageData;

  DetectedObject({
    required this.label,
    required this.confidence,
    required this.dangerLevel,
    required this.timestamp,
    this.imageData,
  });
}

class DangerDetectionService extends ChangeNotifier {
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  final List<DetectedObject> _detections = [];
  List<DetectedObject> get detections => List.unmodifiable(_detections);

  DetectedObject? _lastDetection;
  DetectedObject? get lastDetection => _lastDetection;

  String? _error;
  String? get error => _error;

  Timer? _captureTimer;

  // Dangerous objects to detect (simple keyword-based detection)
  final Map<String, DangerLevel> _dangerousObjects = {
    'fire': DangerLevel.high,
    'flame': DangerLevel.high,
    'smoke': DangerLevel.high,
    'knife': DangerLevel.medium,
    'weapon': DangerLevel.high,
    'gun': DangerLevel.high,
    'sharp': DangerLevel.medium,
    'broken': DangerLevel.medium,
    'spill': DangerLevel.low,
    'wet': DangerLevel.low,
    'obstacle': DangerLevel.low,
  };

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _error = null;
    notifyListeners();

    // Capture frame every 2 seconds
    _captureTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _captureAndAnalyze();
    });

    debugPrint('DangerDetection: Started monitoring');
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _captureTimer?.cancel();
    _captureTimer = null;
    notifyListeners();
    debugPrint('DangerDetection: Stopped monitoring');
  }

  Future<void> _captureAndAnalyze() async {
    try {
      final bytes = await Esp32CamService().captureJpeg(
        captureUrl: ApiConfig.esp32CamCaptureUrl,
      );

      if (bytes.isEmpty) {
        debugPrint('DangerDetection: Empty image captured');
        return;
      }

      // Simulate object detection (in production, use ML model)
      final detected = await _analyzeImage(bytes);

      if (detected != null) {
        _detections.add(detected);
        _lastDetection = detected;

        // Keep only last 50 detections
        if (_detections.length > 50) {
          _detections.removeAt(0);
        }

        // Trigger alert if danger detected
        if (detected.dangerLevel.index >= DangerLevel.medium.index) {
          await _triggerAlert(detected);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('DangerDetection ERROR: $e');
      _error = e.toString();
    }
  }

  Future<DetectedObject?> _analyzeImage(Uint8List imageData) async {
    // Simulate detection delay
    await Future.delayed(const Duration(milliseconds: 100));

    // For demo: randomly detect objects (10% chance)
    if (DateTime.now().millisecond % 10 != 0) return null;

    // Simulate detection
    final dangerItems = _dangerousObjects.entries.toList();
    final randomIndex = DateTime.now().millisecond % dangerItems.length;
    final item = dangerItems[randomIndex];

    final confidence = 0.6 + (DateTime.now().millisecond % 40) / 100;

    return DetectedObject(
      label: item.key,
      confidence: confidence,
      dangerLevel: item.value,
      timestamp: DateTime.now(),
      imageData: imageData,
    );
  }

  Future<void> _triggerAlert(DetectedObject detection) async {
    // Vibrate if available
    if (await Vibration.hasVibrator() ?? false) {
      await Vibration.vibrate(pattern: [0, 500, 200, 500]);
    }

    debugPrint('DangerDetection ALERT: ${detection.label} (${detection.dangerLevel})');
  }

  void clearDetections() {
    _detections.clear();
    _lastDetection = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
