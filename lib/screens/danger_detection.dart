import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/danger_detection_service.dart';
import '../utils/constants.dart';

class DangerDetectionScreen extends StatefulWidget {
  static const String routeName = '/danger-detection';

  const DangerDetectionScreen({super.key});

  @override
  State<DangerDetectionScreen> createState() => _DangerDetectionScreenState();
}

class _DangerDetectionScreenState extends State<DangerDetectionScreen> {
  @override
  void initState() {
    super.initState();
    // Start monitoring when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DangerDetectionService>().startMonitoring();
    });
  }

  @override
  void dispose() {
    context.read<DangerDetectionService>().stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DangerDetectionService>();
    final lastDetection = service.lastDetection;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Danger Detection'),
        actions: [
          if (service.detections.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                service.clearDetections();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          _buildStatusCard(service, lastDetection),

          const SizedBox(height: AppSpacing.md),

          // Detection History
          Expanded(
            child: _buildDetectionList(service),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(DangerDetectionService service, DetectedObject? lastDetection) {
    final isDanger = (lastDetection?.dangerLevel.index ?? 0) >= DangerLevel.medium.index;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDanger ? Colors.red.withOpacity(0.2) : AppColors.cardBackground,
        border: Border.all(
          color: isDanger ? Colors.red : AppColors.border,
          width: isDanger ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDanger ? Icons.warning : Icons.check_circle,
                color: isDanger ? Colors.red : AppColors.accentGreen,
                size: 48,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                isDanger ? 'DANGER DETECTED!' : 'Monitoring Active',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDanger ? Colors.red : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (lastDetection != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Last: ${lastDetection.label.toUpperCase()}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _getDangerColor(lastDetection.dangerLevel),
              ),
            ),
            Text(
              'Confidence: ${(lastDetection.confidence * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIndicatorDot('Safe', AppColors.accentGreen, 
                lastDetection?.dangerLevel == DangerLevel.none || lastDetection == null),
              const SizedBox(width: AppSpacing.md),
              _buildIndicatorDot('Low', Colors.yellow, 
                lastDetection?.dangerLevel == DangerLevel.low),
              const SizedBox(width: AppSpacing.md),
              _buildIndicatorDot('Medium', Colors.orange, 
                lastDetection?.dangerLevel == DangerLevel.medium),
              const SizedBox(width: AppSpacing.md),
              _buildIndicatorDot('High', Colors.red, 
                lastDetection?.dangerLevel == DangerLevel.high),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorDot(String label, Color color, bool isActive) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : color.withOpacity(0.3),
            border: isActive ? Border.all(color: Colors.white, width: 2) : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? color : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionList(DangerDetectionService service) {
    if (service.detections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No dangers detected',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Monitoring ESP32-CAM feed...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    final detections = service.detections.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: detections.length,
      itemBuilder: (context, index) {
        final detection = detections[index];
        return _buildDetectionCard(detection);
      },
    );
  }

  Widget _buildDetectionCard(DetectedObject detection) {
    final color = _getDangerColor(detection.dangerLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: AppColors.cardBackground,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getDangerIcon(detection.dangerLevel),
            color: color,
          ),
        ),
        title: Text(
          detection.label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              _formatTimestamp(detection.timestamp),
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            detection.dangerLevel.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getDangerColor(DangerLevel level) {
    switch (level) {
      case DangerLevel.none:
        return AppColors.accentGreen;
      case DangerLevel.low:
        return Colors.yellow;
      case DangerLevel.medium:
        return Colors.orange;
      case DangerLevel.high:
        return Colors.red;
    }
  }

  IconData _getDangerIcon(DangerLevel level) {
    switch (level) {
      case DangerLevel.none:
        return Icons.check_circle;
      case DangerLevel.low:
        return Icons.info;
      case DangerLevel.medium:
        return Icons.warning;
      case DangerLevel.high:
        return Icons.dangerous;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
