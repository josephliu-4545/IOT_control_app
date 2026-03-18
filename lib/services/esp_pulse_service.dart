import 'dart:async';

import 'package:http/http.dart' as http;

class EspPulseService {
  final Uri endpoint;

  EspPulseService({required this.endpoint});

  Future<int> fetchRawPulseValue() async {
    final response = await http
        .get(endpoint)
        .timeout(const Duration(seconds: 2), onTimeout: () {
      throw TimeoutException('ESP request timed out');
    });

    if (response.statusCode != 200) {
      throw StateError('ESP returned status ${response.statusCode}');
    }

    // Common ESP responses are plain text like: "512" or "Value: 512".
    final raw = response.body.trim();
    final match = RegExp(r'(\d+)').firstMatch(raw);
    if (match == null) {
      throw FormatException('Could not parse pulse value from: $raw');
    }

    final value = int.parse(match.group(1)!);
    // ESP8266 ADC is usually 0..1023, but allow wider values just in case.
    return value;
  }
}
