import 'dart:async';
import 'dart:convert';

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

  /// Fetches heart rate BPM from endpoint that returns both raw and BPM data.
  /// Expected response formats:
  /// - JSON: {"raw": 512, "bpm": 72}
  /// - Plain text with two numbers: "512,72" or "Raw: 512, BPM: 72"
  Future<int> fetchHeartRateBpm() async {
    final response = await http
        .get(endpoint)
        .timeout(const Duration(seconds: 2), onTimeout: () {
      throw TimeoutException('ESP request timed out');
    });

    if (response.statusCode != 200) {
      throw StateError('ESP returned status ${response.statusCode}');
    }

    final body = response.body.trim();

    // Try JSON format first: {"raw": 512, "bpm": 72}
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final bpm = json['bpm'] ?? json['BPM'] ?? json['heartRate'] ?? json['heart_rate'];
      if (bpm != null) {
        return (bpm is int) ? bpm : int.parse(bpm.toString());
      }
    } catch (_) {
      // Not JSON, try other formats
    }

    // Try pattern: two numbers separated by comma (raw,bpm)
    final commaMatch = RegExp(r'\d+[,\s]+(\d+)').firstMatch(body);
    if (commaMatch != null) {
      return int.parse(commaMatch.group(1)!);
    }

    // Try pattern: "BPM: 72" or "bpm: 72"
    final bpmMatch = RegExp(r'[Bb][Pp][Mm][:\s]+(\d+)').firstMatch(body);
    if (bpmMatch != null) {
      return int.parse(bpmMatch.group(1)!);
    }

    // Try pattern: "Real Heart Rate: 120" or "Heart Rate: 72"
    final heartRateMatch = RegExp(r'[Hh]eart\s*[Rr]ate[\s\w]*:\s*(\d+)').firstMatch(body);
    if (heartRateMatch != null) {
      return int.parse(heartRateMatch.group(1)!);
    }

    // Fallback: return second number found
    final numbers = RegExp(r'(\d+)').allMatches(body).toList();
    if (numbers.length >= 2) {
      return int.parse(numbers[1].group(1)!);
    }

    throw FormatException('Could not parse BPM from response: $body');
  }
}
