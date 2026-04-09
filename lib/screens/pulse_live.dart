import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../gen/app_localizations.dart';
import '../utils/constants.dart';
import '../services/pulse_view_model.dart';

class PulseLiveScreen extends StatelessWidget {
  static const String routeName = '/pulse-live';

  const PulseLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<PulseViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pulseRawTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
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
                      l10n.currentRaw,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.1,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      vm.currentValue?.toString() ?? '--',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      vm.statusText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: vm.isOnline
                                ? AppColors.textSecondary
                                : AppColors.accentRed,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: _PulseSparkline(values: vm.history),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseSparkline extends StatelessWidget {
  final List<int> values;

  const _PulseSparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasData = values.length >= 2;

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
              painter: _PulseSparklinePainter(values),
              child: Container(),
            )
          : Center(
              child: Text(
                l10n.waitingForPulseData,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
    );
  }
}

class _PulseSparklinePainter extends CustomPainter {
  final List<int> values;

  _PulseSparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final path = Path();
    final linePaint = Paint()
      ..color = AppColors.accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final glowPaint = Paint()
      ..color = AppColors.accentBlue.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final minValue = values.reduce(min).toDouble();
    final maxValue = values.reduce(max).toDouble();
    final delta = maxValue - minValue == 0 ? 1 : maxValue - minValue;

    final double dxStep = size.width / (values.length - 1);
    const double paddingTop = 8;
    const double paddingBottom = 8;

    Offset pointFor(int index, int value) {
      final double x = index * dxStep;
      final double normalized = (value - minValue) / delta;
      final double y = size.height - paddingBottom -
          normalized * (size.height - paddingTop - paddingBottom);
      return Offset(x, y);
    }

    final first = pointFor(0, values[0]);
    path.moveTo(first.dx, first.dy);

    for (int i = 1; i < values.length; i++) {
      final p = pointFor(i, values[i]);
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _PulseSparklinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
