import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class LiveDashboardResponse {
  final Map<String, dynamic>? latest;
  final List<Map<String, dynamic>> history;
  final Map<String, dynamic> summary;

  const LiveDashboardResponse({
    required this.latest,
    required this.history,
    required this.summary,
  });

  factory LiveDashboardResponse.fromJson(Map<String, dynamic> json) {
    final latestRaw = json['latest'];
    final historyRaw = json['history'];
    final summaryRaw = json['summary'];

    return LiveDashboardResponse(
      latest: latestRaw is Map<String, dynamic>
          ? latestRaw
          : (latestRaw is Map ? Map<String, dynamic>.from(latestRaw) : null),
      history: historyRaw is List
          ? historyRaw
              .whereType<Object?>()
              .map((e) => e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map))
              .toList()
          : const <Map<String, dynamic>>[],
      summary: summaryRaw is Map<String, dynamic>
          ? summaryRaw
          : (summaryRaw is Map ? Map<String, dynamic>.from(summaryRaw) : const {}),
    );
  }
}

class DashboardApiService {
  final http.Client _client;

  DashboardApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<LiveDashboardResponse> fetchDeviceDashboard({
    String baseUrl = ApiConfig.baseUrl,
    String deviceId = ApiConfig.deviceId,
    String deviceToken = ApiConfig.deviceToken,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      path: '/device/dashboard',
      queryParameters: {
        'deviceId': deviceId,
      },
    );

    final res = await _client.get(
      uri,
      headers: {
        'x-device-id': deviceId,
        'x-device-token': deviceToken,
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw Exception('Unexpected response format');
    }

    final json = Map<String, dynamic>.from(decoded);
    if (json['ok'] != true) {
      throw Exception('Backend returned ok=false');
    }

    return LiveDashboardResponse.fromJson(json);
  }
}
