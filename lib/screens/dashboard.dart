// lib/screens/dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart'; // for DashboardViewModel
import '../utils/constants.dart';
import '../widgets/sensor_card.dart';
import 'health.dart';

class DashboardScreen extends StatelessWidget {
  static const String routeName = '/';

  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final snapshot = viewModel.currentSnapshot;
    final isLoading = viewModel.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Health Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Health details',
            icon: const Icon(Icons.monitor_heart),
            onPressed: () {
              Navigator.of(context).pushNamed(HealthScreen.routeName);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, snapshot, isLoading),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  children: [
                    SensorCard(
                      title: 'Heart Rate',
                      value: snapshot?.heartRateBpm.toString() ?? '--',
                      unit: 'BPM',
                      icon: Icons.favorite,
                      accentColor: AppColors.accentRed,
                      subtitle: snapshot == null
                          ? 'Waiting for data...'
                          : 'Stable',
                    ),
                    SensorCard(
                      title: 'Oxygen',
                      value: snapshot?.oxygenPercent.toString() ?? '--',
                      unit: '%',
                      icon: Icons.bubble_chart,
                      accentColor: AppColors.accentBlue,
                      subtitle: 'SpO₂ level',
                    ),
                    SensorCard(
                      title: 'Wi-Fi Signal',
                      value: snapshot?.wifiSignal.toString() ?? '--',
                      unit: '%',
                      icon: Icons.wifi,
                      accentColor: AppColors.accentGreen,
                      subtitle: snapshot == null
                          ? null
                          : _wifiLabel(snapshot.wifiSignal),
                    ),
                    SensorCard(
                      title: 'Battery',
                      value: snapshot?.batteryLevel.toString() ?? '--',
                      unit: '%',
                      icon: Icons.battery_full,
                      accentColor: Colors.amber,
                      subtitle: snapshot == null
                          ? null
                          : _batteryLabel(snapshot.batteryLevel),
                    ),
                    SensorCard(
                      title: 'Solar',
                      value: snapshot == null
                          ? '--'
                          : (snapshot.isChargingSolar ? 'Charging' : 'Idle'),
                      icon: Icons.wb_sunny,
                      accentColor: Colors.orangeAccent,
                      subtitle: snapshot == null
                          ? null
                          : (snapshot.isChargingSolar
                              ? 'Harvesting energy'
                              : 'No solar input'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic snapshot,
    bool isLoading,
  ) {
    final theme = Theme.of(context);
    final bool isOnline = snapshot?.isOnline ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground,
            (isOnline ? AppColors.accentGreen : AppColors.accentRed)
                .withOpacity(0.08),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.check_circle : Icons.error,
            color: isOnline ? AppColors.accentGreen : AppColors.accentRed,
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOnline ? 'System Online' : 'System Offline',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isLoading
                    ? 'Connecting to ESP32 / Blynk...'
                    : (isOnline
                        ? 'Receiving real-time sensor data'
                        : 'Using fallback / dummy data'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  String _wifiLabel(int value) {
    if (value >= 80) return 'Excellent';
    if (value >= 60) return 'Good';
    if (value >= 40) return 'Fair';
    return 'Weak';
  }

  String _batteryLabel(int value) {
    if (value >= 80) return 'High';
    if (value >= 50) return 'Medium';
    if (value >= 20) return 'Low';
    return 'Critical';
  }
}