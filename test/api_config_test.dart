import 'package:flutter_test/flutter_test.dart';
import 'package:iot_control_app/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('normalizes device base URLs', () {
      expect(
        ApiConfig.normalizeBaseUrl(' http://192.168.1.10 '),
        'http://192.168.1.10/',
      );
      expect(
        ApiConfig.normalizeBaseUrl('http://192.168.1.10/'),
        'http://192.168.1.10/',
      );
    });

    test('validates device URLs', () {
      expect(ApiConfig.validateDeviceUrl('http://192.168.1.10/'), isNull);
      expect(ApiConfig.validateDeviceUrl('https://camera.local/'), isNull);
      expect(ApiConfig.validateDeviceUrl('192.168.1.10'), isNotNull);
      expect(ApiConfig.validateDeviceUrl('ftp://192.168.1.10'), isNotNull);
    });
  });
}
