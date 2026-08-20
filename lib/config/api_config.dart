import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://172.20.10.4:8787',
  );

  static const String deviceId = 'esp32cam-001';
  static const String deviceToken = '123456';

  // Default ESP32-CAM URLs - can be configured in settings
  static const String _defaultEsp32CamBaseUrl = 'http://172.20.10.2/';
  static const String _defaultHeartRateBaseUrl = 'http://172.20.10.8/';
  static const String cameraUrlKey = 'esp32_cam_url';
  static const String heartRateUrlKey = 'heart_rate_url';

  static String _esp32CamBaseUrl = _defaultEsp32CamBaseUrl;
  static String _heartRateBaseUrl = _defaultHeartRateBaseUrl;

  static String get esp32CamBaseUrl => _esp32CamBaseUrl;
  static String get esp32CamStreamUrl => '${_esp32CamBaseUrl}stream';
  static String get esp32CamCaptureUrl => '${_esp32CamBaseUrl}capture';

  static String get heartRateBaseUrl => _heartRateBaseUrl;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _esp32CamBaseUrl = normalizeBaseUrl(
      prefs.getString(cameraUrlKey) ?? _defaultEsp32CamBaseUrl,
    );
    _heartRateBaseUrl = normalizeBaseUrl(
      prefs.getString(heartRateUrlKey) ?? _defaultHeartRateBaseUrl,
    );
  }

  static Future<void> updateEsp32CamUrl(String baseUrl) async {
    _esp32CamBaseUrl = normalizeBaseUrl(baseUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cameraUrlKey, _esp32CamBaseUrl);
  }

  static Future<void> updateHeartRateUrl(String baseUrl) async {
    _heartRateBaseUrl = normalizeBaseUrl(baseUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(heartRateUrlKey, _heartRateBaseUrl);
  }

  static String normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  static String? validateDeviceUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a complete address, for example http://192.168.1.100/';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'Only http:// and https:// addresses are supported.';
    }
    return null;
  }
}
