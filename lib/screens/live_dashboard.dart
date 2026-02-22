import 'package:flutter/material.dart';

import '../services/dashboard_api_service.dart';
import '../utils/constants.dart';

class LiveDashboardScreen extends StatefulWidget {
  static const String routeName = '/live-dashboard';

  const LiveDashboardScreen({super.key});

  @override
  State<LiveDashboardScreen> createState() => _LiveDashboardScreenState();
}

class _LiveDashboardScreenState extends State<LiveDashboardScreen> {
  final DashboardApiService _service = DashboardApiService();

  bool _loading = true;
  String? _error;
  LiveDashboardResponse? _data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchDeviceDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'normal':
      default:
        return Colors.green;
    }
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  String _flagsText(dynamic flags) {
    if (flags is List) {
      final items = flags.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      return items.isEmpty ? '--' : items.join(', ');
    }
    return '--';
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return 0;
  }

  String _primaryStatusFromDoc(Map<String, dynamic> doc) {
    final v = doc['primaryStatus'];
    if (v is String && v.isNotEmpty) return v;
    return 'normal';
  }

  Widget _latestSection(Map<String, dynamic>? latest) {
    final theme = Theme.of(context);
    if (latest == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          color: AppColors.cardBackground,
        ),
        child: Text(
          'No readings yet.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final bpm = _asInt(latest['bpm']);
    final spo2 = _asInt(latest['spo2']);
    final flags = _flagsText(latest['flags']);
    final status = _primaryStatusFromDoc(latest);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        color: AppColors.cardBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart, color: AppColors.textPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Latest Reading',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _metricTile(title: 'BPM', value: '$bpm'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _metricTile(title: 'SpO₂', value: '$spo2%'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Flags: $flags',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _metricTile({required String title, required String value}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        color: AppColors.background.withOpacity(0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summarySection(Map<String, dynamic> summary) {
    final theme = Theme.of(context);

    final critical = _asInt(summary['critical']);
    final warning = _asInt(summary['warning']);
    final normal = _asInt(summary['normal']);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        color: AppColors.cardBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  label: 'Critical',
                  value: '$critical',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _summaryTile(
                  label: 'Warning',
                  value: '$warning',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _summaryTile(
                  label: 'Normal',
                  value: '$normal',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historySection(List<Map<String, dynamic>> history) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        color: AppColors.cardBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'History (last 10)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (history.isEmpty)
            Text(
              'No recent readings.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            )
          else
            ListView.separated(
              itemCount: history.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const Divider(height: 16, color: AppColors.border),
              itemBuilder: (context, index) {
                final item = history[index];
                final bpm = _asInt(item['bpm']);
                final spo2 = _asInt(item['spo2']);
                final flags = _flagsText(item['flags']);
                final status = _primaryStatusFromDoc(item);
                final color = _statusColor(status);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'BPM $bpm  •  SpO₂ $spo2%',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _statusChip(status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Flags: $flags',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Health Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _fetch,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    color: AppColors.cardBackground,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Failed to load dashboard',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _fetch,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...[
                  _latestSection(_data?.latest),
                  const SizedBox(height: AppSpacing.md),
                  _summarySection(_data?.summary ?? const {}),
                  const SizedBox(height: AppSpacing.md),
                  _historySection(_data?.history ?? const []),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
