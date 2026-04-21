import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class Esp32CamService {
  final http.Client _client;

  Esp32CamService({http.Client? client}) : _client = client ?? http.Client();

  Uri _captureUri({required String captureUrl}) {
    return Uri.parse(captureUrl);
  }

  Future<Uint8List> captureJpeg({String? captureUrl}) async {
    final url = captureUrl ?? ApiConfig.esp32CamCaptureUrl;
    final res = await _client.get(
      _captureUri(captureUrl: url),
      headers: {
        'Accept': 'image/jpeg',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('ESP32-CAM capture failed: HTTP ${res.statusCode}');
    }

    final bytes = res.bodyBytes;
    if (bytes.isEmpty) {
      throw Exception('ESP32-CAM capture returned empty body');
    }

    return bytes;
  }
}
