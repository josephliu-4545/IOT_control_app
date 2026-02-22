// lib/screens/dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart'; // for DashboardViewModel
import '../models/environment_analysis.dart';
import '../utils/constants.dart';
import '../widgets/sensor_card.dart';
import '../services/device_command_service.dart';
import 'health.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/';

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Local dummy state for smart glasses ecosystem.
  bool _glassesConnected = true;
  bool _glassesCameraOn = false;
  double _glassesTemperatureC = 26.5;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final snapshot = viewModel.currentSnapshot;
    final isLoading = viewModel.isLoading;
    final EnvironmentAnalysis? latestEnv = viewModel.latestEnvironmentAnalysis;
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

              _buildEnvironmentAnalysisCard(context, latestEnv),
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
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(HealthScreen.routeName);
                      },
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
                      onTap: () => _showWifiInfoDialog(context, snapshot),
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
                      onTap: () => _showBatteryDetailsSheet(context, snapshot),
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
                      onTap: () => _showSolarInfoDialog(context, snapshot),
                    ),
                    // Smart glasses: camera control.
                    SensorCard(
                      title: 'Glasses Camera',
                      value: _glassesCameraOn ? 'On' : 'Off',
                      icon: Icons.videocam,
                      accentColor: AppColors.accentBlue,
                      subtitle: 'Tap to toggle (dummy)',
                      onTap: () => _showGlassesCameraSheet(context),
                    ),
                    // Smart glasses: environment / temperature monitor.
                    SensorCard(
                      title: 'Glasses Env',
                      value: '${_glassesTemperatureC.toStringAsFixed(1)}',
                      unit: '°C',
                      icon: Icons.thermostat,
                      accentColor: AppColors.accentGreen,
                      subtitle: 'Ambient temperature',
                      onTap: () => _showGlassesEnvironmentDialog(context),
                    ),
                    // Smart glasses: connection status.
                    SensorCard(
                      title: 'Glasses Link',
                      value: _glassesConnected ? 'Connected' : 'Offline',
                      icon: Icons.vrpano,
                      accentColor:
                          _glassesConnected ? AppColors.accentGreen : AppColors.accentRed,
                      subtitle: 'Smart glasses status',
                      onTap: () => _showGlassesConnectionDialog(context),
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
                    ? 'Connecting to ESP32 / Firebase...'
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

    Widget _buildEnvironmentAnalysisCard(
    BuildContext context,
    EnvironmentAnalysis? analysis,
  ) {
    final theme = Theme.of(context);

    final String risk = (analysis?.riskLevel?.isNotEmpty ?? false)
        ? analysis!.riskLevel!
        : '--';
    final String lighting = (analysis?.lighting?.isNotEmpty ?? false)
        ? analysis!.lighting!
        : '--';
    final String summary = (analysis?.summary?.isNotEmpty ?? false)
        ? analysis!.summary!
        : 'No environment analysis yet.';
    final String hazardsText = (analysis == null || analysis.hazards.isEmpty)
        ? '--'
        : analysis.hazards.join(', ');

    Future<void> onAnalyzePressed() async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await DeviceCommandService().sendAnalyzeEnvironmentCommand();
        messenger.showSnackBar(
          const SnackBar(content: Text('Analyze My Environment command sent.')),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to send command: $e')),
        );
      }
    }

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
              const Icon(Icons.camera_outdoor, color: AppColors.textPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Environment Analysis',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Risk: $risk',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            summary,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lighting: $lighting',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              Text(
                'Hazards: ${(analysis?.hazards.length ?? 0)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hazardsText == '--' ? 'Hazards: --' : 'Hazards: ${(analysis?.hazards.length ?? 0)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAnalyzePressed,
              icon: const Icon(Icons.analytics),
              label: const Text('Analyze My Environment'),
            ),
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

  void _showBatteryDetailsSheet(BuildContext context, dynamic snapshot) {
    if (snapshot == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final int level = snapshot.batteryLevel;
        final bool charging = snapshot.isChargingSolar;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.battery_full, color: Colors.amber),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Battery details'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Level: $level%'),
              const SizedBox(height: AppSpacing.sm),
              Text('Status: ${_batteryLabel(level)}'),
              const SizedBox(height: AppSpacing.sm),
              Text('Solar charging: ${charging ? 'Active' : 'Inactive'}'),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  void _showWifiInfoDialog(BuildContext context, dynamic snapshot) {
    if (snapshot == null) return;
    final int strength = snapshot.wifiSignal;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Wi-Fi signal'),
          content: Text('Strength: $strength% (${_wifiLabel(strength)})'),
        );
      },
    );
  }

  void _showSolarInfoDialog(BuildContext context, dynamic snapshot) {
    if (snapshot == null) return;
    final bool charging = snapshot.isChargingSolar;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Solar status'),
          content: Text(
            charging
                ? 'Panels are actively charging the system.'
                : 'No significant solar charging detected.',
          ),
        );
      },
    );
  }

  void _showGlassesCameraSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool localCameraState = _glassesCameraOn;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.videocam, color: AppColors.accentBlue),
                      SizedBox(width: AppSpacing.sm),
                      Text('Smart glasses camera'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Camera (dummy toggle)'),
                      Switch(
                        value: localCameraState,
                        onChanged: (value) {
                          setModalState(() {
                            localCameraState = value;
                          });
                          setState(() {
                            _glassesCameraOn = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'In the future this will send a command to Firebase/ESP32 to turn the camera on or off.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGlassesEnvironmentDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Glasses environment'),
          content: Text(
            'Ambient temperature around smart glasses: '
            '${_glassesTemperatureC.toStringAsFixed(1)}°C (dummy)',
          ),
        );
      },
    );
  }

  void _showGlassesConnectionDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Glasses connection'),
          content: Text(
            _glassesConnected
                ? 'Smart glasses are marked as connected (dummy state).'
                : 'Smart glasses are offline.',
          ),
        );
      },
    );
  }
}