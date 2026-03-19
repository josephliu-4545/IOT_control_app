import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'esp_pulse_service.dart';

enum PulseConnectionState {
  connecting,
  connected,
  noData,
  error,
}

class PulseViewModel extends ChangeNotifier {
  final EspPulseService service;
  final Duration interval;
  final bool enableFirestoreWrites;
  final String deviceId;

  Timer? _timer;
  bool _isPolling = false;
  bool _pollInFlight = false;

  int? _currentValue;
  final List<int> _history = [];

  int? _currentBpm;
  final List<DateTime> _beatTimes = [];
  int? _lastValue;
  DateTime? _lastBeatAt;
  final List<int> _window = [];

  DateTime? _lastLiveWriteAt;
  DateTime? _lastSampleWriteAt;
  bool _isWriting = false;

  PulseConnectionState _connectionState = PulseConnectionState.connecting;
  Object? _lastError;
  DateTime? _lastSuccessAt;

  int? get currentValue => _currentValue;

  int? get currentBpm => _currentBpm;

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
    this.interval = const Duration(milliseconds: 100),
    this.enableFirestoreWrites = false,
    this.deviceId = 'esp8266_pulse_01',
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
    if (_pollInFlight) return;
    _pollInFlight = true;
    try {
      final value = await service.fetchRawPulseValue();
      _currentValue = value;
      _append(value);
      _updateBpm(value);
      _lastError = null;
      _lastSuccessAt = DateTime.now();
      _connectionState = PulseConnectionState.connected;
      await _maybeWriteToFirestore();
      notifyListeners();
    } catch (e) {
      _lastError = e;
      // If we have never succeeded, we are still "connecting".
      if (_lastSuccessAt == null) {
        _connectionState = PulseConnectionState.connecting;
      } else {
        // If we had a previous success, treat as error/disconnected.
        _connectionState = PulseConnectionState.error;
      }
      await _maybeWriteToFirestore();
      notifyListeners();
    } finally {
      _pollInFlight = false;
    }
  }

  void _append(int value) {
    _history.add(value);
    // Keep last ~10 seconds of data at 500ms => 20 samples.
    if (_history.length > 200) {
      _history.removeRange(0, _history.length - 200);
    }
  }

  void _updateBpm(int value) {
    _window.add(value);
    if (_window.length > 50) {
      _window.removeAt(0);
    }

    if (_window.length < 10) {
      _lastValue = value;
      return;
    }

    int minV = _window.first;
    int maxV = _window.first;
    int sum = 0;
    for (final v in _window) {
      sum += v;
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }

    final amplitude = maxV - minV;
    if (amplitude < 10) {
      _lastValue = value;
      return;
    }

    final mean = sum / _window.length;
    final threshold = mean + (amplitude * 0.25);

    final prev = _lastValue;
    _lastValue = value;
    if (prev == null) return;

    final now = DateTime.now();
    final bool risingCross = prev < threshold && value >= threshold;
    if (!risingCross) return;

    if (_lastBeatAt != null) {
      final deltaMs = now.difference(_lastBeatAt!).inMilliseconds;
      if (deltaMs < 300) {
        return;
      }
    }

    _lastBeatAt = now;
    _beatTimes.add(now);

    final cutoff = now.subtract(const Duration(seconds: 15));
    while (_beatTimes.isNotEmpty && _beatTimes.first.isBefore(cutoff)) {
      _beatTimes.removeAt(0);
    }

    if (_beatTimes.length < 2) return;

    int rrSumMs = 0;
    int rrCount = 0;
    for (int i = 1; i < _beatTimes.length; i++) {
      final rr = _beatTimes[i].difference(_beatTimes[i - 1]).inMilliseconds;
      if (rr >= 300 && rr <= 2000) {
        rrSumMs += rr;
        rrCount++;
      }
    }

    if (rrCount == 0) return;
    final avgRrMs = rrSumMs / rrCount;
    final bpm = (60000 / avgRrMs).round();
    if (bpm >= 30 && bpm <= 220) {
      _currentBpm = bpm;
    }
  }

  Future<void> _maybeWriteToFirestore() async {
    if (!enableFirestoreWrites) return;
    if (_isWriting) return;

    final now = DateTime.now();
    final bool shouldWriteLive =
        _lastLiveWriteAt == null || now.difference(_lastLiveWriteAt!) >= const Duration(seconds: 2);
    final bool shouldWriteSample =
        _lastSampleWriteAt == null || now.difference(_lastSampleWriteAt!) >= const Duration(seconds: 5);

    if (!shouldWriteLive && !shouldWriteSample) return;

    final bpm = _currentBpm;
    if (bpm == null) return;

    _isWriting = true;
    try {
      final db = FirebaseFirestore.instance;
      final deviceRef = db.collection('devices').doc(deviceId);

      if (shouldWriteLive) {
        await deviceRef.set(
          {
            'pulse_live': {
              'bpm': bpm,
              'online': isOnline,
              'ts': FieldValue.serverTimestamp(),
              'source': 'esp_http',
            },
          },
          SetOptions(merge: true),
        );
        _lastLiveWriteAt = now;
      }

      if (shouldWriteSample) {
        await deviceRef.collection('pulse_samples').add(
          {
            'bpm': bpm,
            'online': isOnline,
            'ts': FieldValue.serverTimestamp(),
            'source': 'esp_http',
          },
        );
        _lastSampleWriteAt = now;
      }
    } catch (e) {
      _lastError = e;
    } finally {
      _isWriting = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
