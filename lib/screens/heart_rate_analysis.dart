import 'package:flutter/material.dart';
import '../models/heart_rate_analytics.dart';
import '../services/heart_rate_analytics_service.dart';
import '../services/health_notification_service.dart';
import '../utils/constants.dart';

class HeartRateAnalysisScreen extends StatefulWidget {
  static const String routeName = '/heart-rate-analysis';

  const HeartRateAnalysisScreen({super.key});

  @override
  State<HeartRateAnalysisScreen> createState() => _HeartRateAnalysisScreenState();
}

class _HeartRateAnalysisScreenState extends State<HeartRateAnalysisScreen> {
  final _analyticsService = HeartRateAnalyticsService();
  final _notificationService = HealthNotificationService();
  HeartRateAnalysis? _analysis;
  List<HealthInsight>? _insights;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
    _notificationService.initialize();
  }

  Future<void> _loadAnalysis() async {
    final analysis = await _analyticsService.generateWeeklyAnalysis();
    final insights = _analyticsService.generateInsights(analysis);

    setState(() {
      _analysis = analysis;
      _insights = insights;
      _isLoading = false;
    });
  }

  Future<void> _showNotifications() async {
    if (_insights == null) return;
    
    for (final insight in _insights!) {
      await _notificationService.showHealthInsight(insight);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health insights sent as notifications')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Heart Rate Analysis', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          if (_insights != null && _insights!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.notifications_active, color: AppColors.accentRed),
              onPressed: _showNotifications,
              tooltip: 'Send notifications',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadAnalysis,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalysis,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStatsGrid(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildHourlyTrendChart(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildAnomaliesSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildInsightsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    if (_analysis == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentRed.withOpacity(0.3), AppColors.accentRed.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentRed.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: AppColors.accentRed, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7-Day Analysis',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_formatDate(_analysis!.periodStart)} - ${_formatDate(_analysis!.periodEnd)}',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildTrendBadge(_analysis!.trend),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _getTrendDescription(_analysis!.trend),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBadge(HealthTrend trend) {
    final (color, icon, text) = switch (trend) {
      HealthTrend.improving => (AppColors.accentGreen, Icons.trending_down, 'Improving'),
      HealthTrend.concerning => (AppColors.accentRed, Icons.warning, 'Attention'),
      HealthTrend.stable => (AppColors.accentBlue, Icons.check_circle, 'Stable'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_analysis == null) return const SizedBox.shrink();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      children: [
        _buildStatCard('Resting HR', '${_analysis!.restingBpm.toStringAsFixed(0)}', 'BPM', AppColors.accentBlue),
        _buildStatCard('Average', '${_analysis!.averageBpm.toStringAsFixed(0)}', 'BPM', AppColors.accentGreen),
        _buildStatCard('Min / Max', '${_analysis!.minBpm.toStringAsFixed(0)} / ${_analysis!.maxBpm.toStringAsFixed(0)}', 'BPM', const Color(0xFFF59E0B)),
        _buildStatCard('Anomalies', '${_analysis!.anomalies.length}', 'detected', AppColors.accentRed),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyTrendChart() {
    if (_analysis == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('24-Hour Pattern', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 150,
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: _HourlyTrendPainter(_analysis!.hourlyTrend),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              Text('12:00', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              Text('23:59', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesSection() {
    if (_analysis == null || _analysis!.anomalies.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.accentGreen),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'No anomalies detected this week',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected Anomalies (${_analysis!.anomalies.length})',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._analysis!.anomalies.take(5).map((a) => _buildAnomalyItem(a)),
          if (_analysis!.anomalies.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                '+ ${_analysis!.anomalies.length - 5} more',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnomalyItem(Anomaly anomaly) {
    final icon = switch (anomaly.type) {
      AnomalyType.elevated => Icons.arrow_upward,
      AnomalyType.low => Icons.arrow_downward,
      AnomalyType.irregular => Icons.warning,
      AnomalyType.trendUp => Icons.trending_up,
      AnomalyType.trendDown => Icons.trending_down,
    };

    final color = switch (anomaly.type) {
      AnomalyType.elevated || AnomalyType.trendUp => const Color(0xFFF59E0B),
      AnomalyType.low || AnomalyType.trendDown => AppColors.accentBlue,
      AnomalyType.irregular => AppColors.accentRed,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anomaly.message,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
                Text(
                  _formatDateTime(anomaly.timestamp),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    if (_insights == null || _insights!.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Insights',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._insights!.map((i) => _buildInsightItem(i)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(HealthInsight insight) {
    final color = switch (insight.severity) {
      InsightSeverity.info => AppColors.accentBlue,
      InsightSeverity.warning => const Color(0xFFF59E0B),
      InsightSeverity.alert => AppColors.accentRed,
    };

    final icon = switch (insight.severity) {
      InsightSeverity.info => Icons.info,
      InsightSeverity.warning => Icons.warning_amber,
      InsightSeverity.alert => Icons.error,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getTrendDescription(HealthTrend trend) {
    return switch (trend) {
      HealthTrend.improving => 'Your heart rate patterns show signs of improved fitness.',
      HealthTrend.concerning => 'Unusual patterns detected. Consider monitoring your health.',
      HealthTrend.stable => 'Your heart rate has been consistent this week.',
    };
  }
}

class _HourlyTrendPainter extends CustomPainter {
  final List<int> hourlyData;

  _HourlyTrendPainter(this.hourlyData);

  @override
  void paint(Canvas canvas, Size size) {
    if (hourlyData.isEmpty || hourlyData.every((v) => v == 0)) return;

    final paint = Paint()
      ..color = AppColors.accentRed
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.accentRed.withOpacity(0.3), AppColors.accentRed.withOpacity(0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final max = hourlyData.reduce((a, b) => a > b ? a : b).toDouble();
    final min = hourlyData.reduce((a, b) => a < b ? a : b).toDouble();
    final range = max - min == 0 ? 1 : max - min;

    final points = <Offset>[];
    for (int i = 0; i < hourlyData.length; i++) {
      final x = (i / (hourlyData.length - 1)) * size.width;
      final y = size.height - ((hourlyData[i] - min) / range) * size.height * 0.8 - size.height * 0.1;
      points.add(Offset(x, y));
    }

    // Draw fill area
    final fillPath = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = AppColors.accentRed
      ..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
