import 'dart:async';

import 'package:flutter/foundation.dart';

import 'esp_pulse_service.dart';
import 'heart_rate_analytics_service.dart';

enum PulseConnectionState {
  connecting,
  connected,
  noData,
  error,
}

class PulseViewModel extends ChangeNotifier {
  final EspPulseService service;
  final Duration interval;
  final HeartRateAnalyticsService analyticsService;

  Timer? _timer;
  bool _isPolling = false;

  int? _currentValue;
  final List<int> _history = [];

  PulseConnectionState _connectionState = PulseConnectionState.connecting;
  Object? _lastError;
  DateTime? _lastSuccessAt;

  int? get currentValue => _currentValue;

  List<int> get history => List.unmodifiable(_history);

  PulseConnectionState get connectionState => _connectionState;

  Object? get lastError => _lastError;

  bool get isOnline => _connectionState == PulseConnectionState.connected;

  String get statusText {
    switch (_connectionState) {
      case PulseConnectionState.connecting:
        return 'Connecting...';
      case PulseConnectionState.connected:
        return 'Connected';
      case PulseConnectionState.noData:
        return 'No data yet';
      case PulseConnectionState.error:
        return _lastError == null ? 'Disconnected' : 'Error: ${_lastError.runtimeType}';
    }
  }

  PulseViewModel({
    required this.service,
    this.interval = const Duration(milliseconds: 500),
    HeartRateAnalyticsService? analyticsService,
  }) : this.analyticsService = analyticsService ?? HeartRateAnalyticsService() {
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
      final value = await service.fetchHeartRateBpm();
      _currentValue = value;
      _append(value);
      
      // Store to analytics database (fire-and-forget)
      analyticsService.storeReading(value, isResting: value < 90);
      
      _lastError = null;
      _lastSuccessAt = DateTime.now();
      _connectionState = PulseConnectionState.connected;
      notifyListeners();
    } catch (e) {
      _lastError = e;
      print('PulseViewModel ERROR: $e');
      // If we have never succeeded, we are still "connecting".
      if (_lastSuccessAt == null) {
        _connectionState = PulseConnectionState.connecting;
      } else {
        // If we had a previous success, treat as error/disconnected.
        _connectionState = PulseConnectionState.error;
      }
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
