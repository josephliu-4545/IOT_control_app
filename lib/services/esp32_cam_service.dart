import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class Esp32CamService {
  final http.Client _client;

  Esp32CamService({http.Client? client}) : _client = client ?? http.Client();

  Uri _captureUri({String captureUrl = ApiConfig.esp32CamCaptureUrl}) {
    return Uri.parse(captureUrl);
  }

  Future<Uint8List> captureJpeg({String captureUrl = ApiConfig.esp32CamCaptureUrl}) async {
    final res = await _client.get(
      _captureUri(captureUrl: captureUrl),
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
