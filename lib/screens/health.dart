// lib/screens/health.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../utils/constants.dart';

class HealthScreen extends StatefulWidget {
  static const String routeName = '/health';

  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final snapshot = viewModel.currentSnapshot;
    final bpm = snapshot?.heartRateBpm ?? 0;
    final history = viewModel.heartRateHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Health'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.05)
                        .animate(_scaleAnimation),
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.accentRed.withOpacity(0.8),
                            AppColors.background,
                          ],
                          center: Alignment.center,
                          radius: 0.85,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentRed.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 60,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            bpm > 0 ? bpm.toString() : '--',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'BPM',
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                      letterSpacing: 1.2,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                flex: 3,
                child: _HeartRateChart(
                  values: history,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Real-time heart rate trend',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeartRateChart extends StatelessWidget {
  final List<int> values;

  const _HeartRateChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final hasData = values.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF020617),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: hasData
          ? CustomPaint(
              painter: _HeartRateChartPainter(values),
              child: Container(),
            )
          : Center(
              child: Text(
                'Waiting for heart rate data...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
    );
  }
}

class _HeartRateChartPainter extends CustomPainter {
  final List<int> values;

  _HeartRateChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final path = Path();
    final linePaint = Paint()
      ..color = AppColors.accentGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final glowPaint = Paint()
      ..color = AppColors.accentGreen.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Compute min/max to scale vertically.
    final minValue = values.reduce(min).toDouble();
    final maxValue = values.reduce(max).toDouble();
    final delta = maxValue - minValue == 0 ? 1 : maxValue - minValue;

    final double dxStep = size.width / (values.length - 1);
    const double paddingTop = 8;
    const double paddingBottom = 8;

    // Convert value -> offset in canvas coordinates.
    Offset pointFor(int index, int value) {
      final double x = index * dxStep;
      final double normalized = (value - minValue) / delta;
      final double y = size.height - paddingBottom - normalized *
          (size.height - paddingTop - paddingBottom);
      return Offset(x, y);
    }

    path.moveTo(
      pointFor(0, values[0]).dx,
      pointFor(0, values[0]).dy,
    );

    for (int i = 1; i < values.length; i++) {
      final p = pointFor(i, values[i]);
      path.lineTo(p.dx, p.dy);
    }

    // Draw glow then line.
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _HeartRateChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}