import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';

class EnvironmentAnalysisApiService {
  final http.Client _client;

  EnvironmentAnalysisApiService({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>> uploadEnvironmentImage({
    required Uint8List jpegBytes,
    String baseUrl = ApiConfig.baseUrl,
    String deviceId = ApiConfig.deviceId,
    String deviceToken = ApiConfig.deviceToken,
    String? commandId,
  }) async {
    final uri = Uri.parse(baseUrl).replace(path: '/device/upload-image');

    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll({
      'x-device-id': deviceId,
      'x-device-token': deviceToken,
    });

    if (commandId != null && commandId.isNotEmpty) {
      req.fields['commandId'] = commandId;
    }

    req.files.add(
      http.MultipartFile.fromBytes(
        'image',
        jpegBytes,
        filename: 'capture.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Upload failed: HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw Exception('Unexpected upload response');
    }

    return Map<String, dynamic>.from(decoded);
  }
}
