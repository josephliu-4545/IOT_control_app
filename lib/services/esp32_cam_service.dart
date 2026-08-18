import 'dart:typed_data';
import 'dart:async';

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
    final res = await _client
        .get(_captureUri(captureUrl: url), headers: {'Accept': 'image/jpeg'})
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Camera did not respond within 5 seconds');
          },
        );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('ESP32-CAM capture failed: HTTP ${res.statusCode}');
    }

    final bytes = res.bodyBytes;
    if (bytes.isEmpty) {
      throw Exception('ESP32-CAM capture returned empty body');
    }

    final contentType = res.headers['content-type']?.toLowerCase();
    final hasJpegSignature =
        bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8;
    if (contentType?.contains('image') != true && !hasJpegSignature) {
      throw const FormatException(
        'Camera responded, but did not return an image',
      );
    }

    return bytes;
  }
}
