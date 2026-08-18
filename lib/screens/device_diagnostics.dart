import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/esp32_cam_service.dart';
import '../services/esp_pulse_service.dart';
import '../utils/constants.dart';

enum _TestState { idle, testing, success, failure }

class DeviceDiagnosticsScreen extends StatefulWidget {
  static const String routeName = '/device-diagnostics';

  const DeviceDiagnosticsScreen({super.key});

  @override
  State<DeviceDiagnosticsScreen> createState() =>
      _DeviceDiagnosticsScreenState();
}

class _DeviceDiagnosticsScreenState extends State<DeviceDiagnosticsScreen> {
  final _cameraController = TextEditingController();
  final _heartController = TextEditingController();
  _TestState _cameraState = _TestState.idle;
  _TestState _heartState = _TestState.idle;
  String? _cameraDetail;
  String? _heartDetail;
  Uint8List? _cameraImage;

  @override
  void initState() {
    super.initState();
    _cameraController.text = ApiConfig.esp32CamBaseUrl;
    _heartController.text = ApiConfig.heartRateBaseUrl;
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  Future<bool> _validateAndSave() async {
    final cameraError = ApiConfig.validateDeviceUrl(_cameraController.text);
    final heartError = ApiConfig.validateDeviceUrl(_heartController.text);
    if (cameraError != null || heartError != null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cameraError ?? heartError!)));
      return false;
    }
    await ApiConfig.updateEsp32CamUrl(_cameraController.text);
    await ApiConfig.updateHeartRateUrl(_heartController.text);
    _cameraController.text = ApiConfig.esp32CamBaseUrl;
    _heartController.text = ApiConfig.heartRateBaseUrl;
    return true;
  }

  Future<void> _testCamera() async {
    if (!await _validateAndSave()) return;
    setState(() {
      _cameraState = _TestState.testing;
      _cameraDetail = 'Contacting ${ApiConfig.esp32CamCaptureUrl}';
    });
    final stopwatch = Stopwatch()..start();
    try {
      final bytes = await Esp32CamService().captureJpeg();
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _cameraState = _TestState.success;
        _cameraImage = bytes;
        _cameraDetail =
            'Valid image • ${bytes.lengthInBytes ~/ 1024} KB • ${stopwatch.elapsedMilliseconds} ms';
      });
    } catch (error) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _cameraState = _TestState.failure;
        _cameraDetail = _friendlyError(error, device: 'camera');
      });
    }
  }

  Future<void> _testHeartSensor() async {
    if (!await _validateAndSave()) return;
    setState(() {
      _heartState = _TestState.testing;
      _heartDetail = 'Contacting ${ApiConfig.heartRateBaseUrl}';
    });
    final stopwatch = Stopwatch()..start();
    try {
      final bpm = await EspPulseService(
        endpoint: Uri.parse(ApiConfig.heartRateBaseUrl),
      ).fetchHeartRateBpm();
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _heartState = _TestState.success;
        _heartDetail =
            '$bpm BPM • valid response • ${stopwatch.elapsedMilliseconds} ms';
      });
    } catch (error) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _heartState = _TestState.failure;
        _heartDetail = _friendlyError(error, device: 'heart-rate sensor');
      });
    }
  }

  Future<void> _testBoth() async {
    await Future.wait([_testCamera(), _testHeartSensor()]);
  }

  String _friendlyError(Object error, {required String device}) {
    final message = error.toString();
    if (message.contains('timed out') || message.contains('Timeout')) {
      return 'Timed out. Confirm the $device is powered on and on the same Wi-Fi network.';
    }
    if (message.contains('SocketException') ||
        message.contains('Connection refused')) {
      return 'Could not reach the $device. Check its IP address and the phone’s Wi-Fi.';
    }
    if (message.contains('FormatException') || message.contains('parse')) {
      return 'The device responded, but its data format was not recognized: $message';
    }
    return message.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device diagnostics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Test direct device connections',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your phone and both devices must be connected to the same Wi-Fi network.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            _DeviceTestCard(
              icon: Icons.videocam_outlined,
              title: 'ESP32 camera',
              endpointLabel: 'Base address',
              controller: _cameraController,
              hintText: 'http://192.168.1.100/',
              state: _cameraState,
              detail: _cameraDetail,
              buttonLabel: 'Test camera',
              onTest: _testCamera,
              preview: _cameraImage == null
                  ? null
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _cameraImage!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DeviceTestCard(
              icon: Icons.monitor_heart_outlined,
              title: 'Heart-rate sensor',
              endpointLabel: 'Sensor address',
              controller: _heartController,
              hintText: 'http://192.168.1.101/',
              state: _heartState,
              detail: _heartDetail,
              buttonLabel: 'Test heart sensor',
              onTest: _testHeartSensor,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed:
                  _cameraState == _TestState.testing ||
                      _heartState == _TestState.testing
                  ? null
                  : _testBoth,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Test both devices'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'These tests communicate directly with the devices. Firebase and cloud analysis are tested separately by the dashboard.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTestCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String endpointLabel;
  final TextEditingController controller;
  final String hintText;
  final _TestState state;
  final String? detail;
  final String buttonLabel;
  final VoidCallback onTest;
  final Widget? preview;

  const _DeviceTestCard({
    required this.icon,
    required this.title,
    required this.endpointLabel,
    required this.controller,
    required this.hintText,
    required this.state,
    required this.detail,
    required this.buttonLabel,
    required this.onTest,
    this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _TestState.success => AppColors.accentGreen,
      _TestState.failure => AppColors.accentRed,
      _TestState.testing => AppColors.accentBlue,
      _TestState.idle => AppColors.textSecondary,
    };
    final status = switch (state) {
      _TestState.success => 'Connected',
      _TestState.failure => 'Test failed',
      _TestState.testing => 'Testing…',
      _TestState.idle => 'Not tested',
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state == _TestState.idle
              ? AppColors.border
              : color.withValues(alpha: .7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusPill(label: status, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: endpointLabel,
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ],
          if (preview != null) ...[
            const SizedBox(height: AppSpacing.md),
            preview!,
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: state == _TestState.testing ? null : onTest,
              icon: state == _TestState.testing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
