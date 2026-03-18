import 'dart:async';

import 'package:flutter/foundation.dart';

import 'esp_pulse_service.dart';

class PulseViewModel extends ChangeNotifier {
  final EspPulseService service;
  final Duration interval;

  Timer? _timer;
  bool _isPolling = false;

  int? _currentValue;
  final List<int> _history = [];

  bool _isOnline = false;
  String _statusText = 'Connecting...';

  int? get currentValue => _currentValue;

  List<int> get history => List.unmodifiable(_history);

  bool get isOnline => _isOnline;

  String get statusText => _statusText;

  PulseViewModel({
    required this.service,
    this.interval = const Duration(milliseconds: 500),
  }) {
    start();
  }

  void start() {
    if (_isPolling) return;
    _isPolling = true;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _pollOnce());
    _pollOnce();
  }

  Future<void> _pollOnce() async {
    try {
      final value = await service.fetchRawPulseValue();
      _currentValue = value;
      _append(value);
      _isOnline = true;
      _statusText = 'Live from ESP8266';
      notifyListeners();
    } catch (e) {
      _isOnline = false;
      _statusText = 'Offline: ${e.runtimeType}';
      notifyListeners();
    }
  }

  void _append(int value) {
    _history.add(value);
    // Keep last ~10 seconds of data at 500ms => 20 samples.
    if (_history.length > 200) {
      _history.removeRange(0, _history.length - 200);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
