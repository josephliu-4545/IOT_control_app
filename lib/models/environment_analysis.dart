// lib/models/environment_analysis.dart

class EnvironmentAnalysis {
  final String deviceId;
  final String? imageUrl;
  final String? lighting;
  final List<String> hazards;
  final String? summary;
  final String? riskLevel;

  const EnvironmentAnalysis({
    required this.deviceId,
    required this.imageUrl,
    required this.lighting,
    required this.hazards,
    required this.summary,
    required this.riskLevel,
  });

  factory EnvironmentAnalysis.fromFirestore({
    required Map<String, dynamic> data,
  }) {
    final result = (data['result'] as Map?)?.cast<String, dynamic>() ?? const {};

    final hazardsRaw = result['hazards'];
    final hazards = hazardsRaw is List
        ? hazardsRaw.map((e) => e.toString()).toList()
        : const <String>[];

    return EnvironmentAnalysis(
      deviceId: (data['deviceId'] as String?) ?? '',
      imageUrl: data['imageUrl'] as String?,
      lighting: result['lighting'] as String?,
      hazards: hazards,
      summary: result['summary'] as String?,
      riskLevel: result['risk_level'] as String?,
    );
  }
}
