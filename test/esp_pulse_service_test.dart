import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:iot_control_app/services/esp_pulse_service.dart';

void main() {
  Future<int> parse(String body) {
    final client = MockClient((_) async => http.Response(body, 200));
    return EspPulseService(
      endpoint: Uri.parse('http://sensor.local/'),
      client: client,
    ).fetchHeartRateBpm();
  }

  test('parses JSON heart-rate response', () async {
    expect(await parse('{"raw":512,"bpm":72}'), 72);
  });

  test('parses labeled heart-rate response', () async {
    expect(await parse('Raw: 512, BPM: 81'), 81);
  });

  test('rejects an unrecognized response', () async {
    await expectLater(parse('sensor ready'), throwsA(isA<FormatException>()));
  });
}
