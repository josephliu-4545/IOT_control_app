class ApiConfig {
  static const String baseUrl = 'https://iot-control-app.onrender.com';

  static const String deviceId = 'esp32cam-001';
  static const String deviceToken = '123456';

  // Default ESP32-CAM URLs - can be configured in settings
  static String _esp32CamBaseUrl = 'http://172.20.10.4/';

  static String get esp32CamBaseUrl => _esp32CamBaseUrl;
  static String get esp32CamStreamUrl => '${_esp32CamBaseUrl}stream';
  static String get esp32CamCaptureUrl => '${_esp32CamBaseUrl}capture';

  static void updateEsp32CamUrl(String baseUrl) {
    _esp32CamBaseUrl = baseUrl;
  }

  // Heart Rate Sensor Endpoint - returns raw + BPM data
  static const String heartRateBaseUrl = 'http://172.20.10.8/';
}