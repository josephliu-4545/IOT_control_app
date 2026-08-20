import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';

import '../config/api_config.dart';
import '../utils/environment_summary.dart';
import 'environment_analysis_api_service.dart';
import 'esp32_cam_service.dart';
import 'tts_service.dart';

enum VoiceAssistantState { idle, listening, processing, speaking, muted, error }

enum VoiceIntent {
  describeEnvironment,
  cameraStatus,
  repeat,
  stop,
  help,
  unknown,
}

VoiceIntent parseVoiceIntent(String words) {
  final text = words.toLowerCase().trim();
  if (text.contains('what is in front') ||
      text.contains("what's in front") ||
      text.contains('whats in front') ||
      text.contains('describe my surroundings') ||
      text.contains('describe the surroundings') ||
      text.contains('what can you see') ||
      text.contains('identify what')) {
    return VoiceIntent.describeEnvironment;
  }
  if (text.contains('camera') &&
      (text.contains('connected') ||
          text.contains('online') ||
          text.contains('working') ||
          text.contains('status'))) {
    return VoiceIntent.cameraStatus;
  }
  if (text == 'repeat' || text.contains('say that again')) {
    return VoiceIntent.repeat;
  }
  if (text == 'stop' || text == 'cancel' || text.contains('stop speaking')) {
    return VoiceIntent.stop;
  }
  if (text == 'help' || text.contains('what can i ask')) {
    return VoiceIntent.help;
  }
  return VoiceIntent.unknown;
}

class VoiceAssistantService extends ChangeNotifier {
  static const MethodChannel _volumeChannel = MethodChannel(
    'iot_control_app/volume_shortcut',
  );

  final SpeechToText _speech;
  final TtsService _tts;
  final Esp32CamService _camera;
  final EnvironmentAnalysisApiService _analysisApi;
  final Future<Uint8List> Function()? _imageProvider;
  final Future<void> Function()? _analyzeEnvironmentShortcut;

  VoiceAssistantState _state = VoiceAssistantState.idle;
  String _statusMessage = 'Ask what is in front of you';
  String _heardWords = '';
  String? _lastResponse;
  String _localeId = 'en-US';
  String? _speechLocaleId;
  bool _speechReady = false;
  bool _handlingResult = false;
  bool _recognizerConfirmedListening = false;
  bool _disposed = false;
  Future<void>? _backendWarmUp;
  Timer? _partialResultTimer;
  Timer? _emptyResultTimer;

  VoiceAssistantService({
    SpeechToText? speech,
    TtsService? tts,
    Esp32CamService? camera,
    EnvironmentAnalysisApiService? analysisApi,
    Future<Uint8List> Function()? imageProvider,
    Future<void> Function()? analyzeEnvironmentShortcut,
  }) : _speech = speech ?? SpeechToText(),
       _tts = tts ?? TtsService(),
       _camera = camera ?? Esp32CamService(),
       _analysisApi = analysisApi ?? EnvironmentAnalysisApiService(),
       _imageProvider = imageProvider,
       _analyzeEnvironmentShortcut = analyzeEnvironmentShortcut;

  VoiceAssistantState get state => _state;
  String get statusMessage => _statusMessage;
  String get heardWords => _heardWords;
  bool get isBusy =>
      _state == VoiceAssistantState.listening ||
      _state == VoiceAssistantState.processing ||
      _state == VoiceAssistantState.speaking;

  Future<void> initialize({required String localeId}) async {
    _localeId = localeId;
    try {
      await _tts.initialize();
      await _tts.setLanguage(localeId);
      _speechReady = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      if (_speechReady) {
        _speechLocaleId = await _resolveSpeechLocale(localeId);
      }
      _backendWarmUp ??= _warmBackend();
      _volumeChannel.setMethodCallHandler(_handleVolumeShortcut);
    } catch (error) {
      debugPrint('VOICE ASSISTANT INIT ERROR: $error');
      _speechReady = false;
      _state = VoiceAssistantState.error;
      _statusMessage = 'Voice recognition is unavailable on this device.';
    }
    _notify();
  }

  Future<void> _handleVolumeShortcut(MethodCall call) async {
    if (call.method == 'activateEnvironmentAnalysis') {
      if (_analyzeEnvironmentShortcut != null) {
        await _speech.stop();
        await _tts.stop();
        await _analyzeEnvironmentShortcut();
      }
      return;
    }
    if (call.method != 'activateAssistant') return;
    final args = (call.arguments as Map?)?.cast<Object?, Object?>();
    final currentVolume = args?['currentVolume'] as int? ?? 0;
    if (currentVolume <= 0) {
      await warnVolumeMuted();
      return;
    }
    await startListening(localeId: _localeId);
  }

  Future<void> warnVolumeMuted() async {
    _setState(
      VoiceAssistantState.muted,
      'Media volume is muted. Tap Volume Up, then hold it to ask.',
    );
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(pattern: [0, 180, 100, 180, 100, 400]);
    }
  }

  Future<void> startListening({required String localeId}) async {
    if (_state == VoiceAssistantState.processing) return;
    if (!await _hasAudibleMediaVolume()) return;
    _localeId = localeId;
    _handlingResult = false;
    _recognizerConfirmedListening = false;
    _heardWords = '';
    _partialResultTimer?.cancel();
    _emptyResultTimer?.cancel();

    if (!_speechReady) {
      await initialize(localeId: localeId);
    }
    if (!_speechReady) {
      await _respond(
        'Speech recognition is not available. Check microphone permission and the phone speech service.',
        error: true,
      );
      return;
    }

    await _speech.cancel();
    await _tts.stop();
    _setState(VoiceAssistantState.processing, 'Preparing microphone…');
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 100);
    }
    await _tts.speak('Listening');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _speechLocaleId = await _resolveSpeechLocale(localeId);
    _setState(VoiceAssistantState.listening, 'Listening… Speak now.');

    final started = await _speech.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 5),
        localeId: _speechLocaleId,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
    if (!started && _state == VoiceAssistantState.listening) {
      await _respond(
        'The phone speech service could not start. Check microphone permission and try again.',
        error: true,
      );
    }
  }

  Future<String?> _resolveSpeechLocale(String requestedLocale) async {
    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) return null;
      final requested = requestedLocale.toLowerCase().replaceAll('-', '_');
      for (final locale in locales) {
        if (locale.localeId.toLowerCase().replaceAll('-', '_') == requested) {
          return locale.localeId;
        }
      }
      final language = requested.split('_').first;
      for (final locale in locales) {
        final candidate = locale.localeId.toLowerCase().replaceAll('-', '_');
        if (candidate.split('_').first == language) return locale.localeId;
      }
      return null;
    } catch (error) {
      debugPrint('SPEECH LOCALE LOOKUP ERROR: $error');
      return null;
    }
  }

  Future<void> _warmBackend() async {
    try {
      await _analysisApi.warmUp();
      debugPrint('VOICE ASSISTANT BACKEND: ready');
    } catch (error) {
      debugPrint('VOICE ASSISTANT BACKEND WARM-UP ERROR: $error');
    }
  }

  Future<bool> _hasAudibleMediaVolume() async {
    try {
      final currentVolume =
          await _volumeChannel.invokeMethod<int>('getMediaVolume') ?? 1;
      if (currentVolume <= 0) {
        await warnVolumeMuted();
        return false;
      }
    } on MissingPluginException {
      // Non-Android platforms do not expose the hardware-volume shortcut.
    } on PlatformException catch (error) {
      debugPrint('MEDIA VOLUME CHECK ERROR: $error');
    }
    return true;
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _emptyResultTimer?.cancel();
    final recognizedWords = result.recognizedWords.trim();
    // Some Android recognizers emit a correct partial transcript followed by
    // an empty final result. Keep the last useful transcript instead of
    // erasing it immediately before command parsing.
    if (recognizedWords.isNotEmpty) {
      _heardWords = recognizedWords;
      _statusMessage = 'Heard: $_heardWords';
      _notify();
    }
    if (result.finalResult) {
      _partialResultTimer?.cancel();
      unawaited(_processWords(_heardWords));
    } else if (_heardWords.isNotEmpty) {
      // A few Android speech services never mark a good partial result final.
      // Process it after a short period with no transcript changes.
      _partialResultTimer?.cancel();
      _partialResultTimer = Timer(const Duration(milliseconds: 1200), () {
        if (!_handlingResult && _heardWords.isNotEmpty) {
          unawaited(_processWords(_heardWords));
        }
      });
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint('VOICE ASSISTANT SPEECH STATUS: $status');
    if (status == 'listening') {
      _recognizerConfirmedListening = true;
      return;
    }
    if ((status == 'done' || status == 'notListening') &&
        _state == VoiceAssistantState.listening &&
        _recognizerConfirmedListening &&
        !_handlingResult) {
      if (_heardWords.isEmpty) {
        _scheduleEmptyResult('I did not hear anything. Please try again.');
      } else {
        unawaited(_processWords(_heardWords));
      }
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (_handlingResult) return;
    debugPrint(
      'VOICE ASSISTANT SPEECH ERROR: ${error.errorMsg} '
      '(permanent=${error.permanent})',
    );
    // Some Android speech services return a useful partial transcript and then
    // report `no_match` instead of marking that transcript as final. Prefer the
    // words already recognized over the late error callback.
    if (_heardWords.trim().isNotEmpty) {
      unawaited(_processWords(_heardWords));
      return;
    }
    _scheduleEmptyResult(_friendlySpeechError(error), error: true);
  }

  void _scheduleEmptyResult(String message, {bool error = false}) {
    _emptyResultTimer?.cancel();
    _emptyResultTimer = Timer(const Duration(milliseconds: 700), () {
      if (_handlingResult || _heardWords.trim().isNotEmpty) return;
      _handlingResult = true;
      unawaited(_respond(message, error: error));
    });
  }

  String _friendlySpeechError(SpeechRecognitionError error) {
    final code = error.errorMsg.toLowerCase();
    if (code.contains('permission')) {
      return 'Microphone access is unavailable. Allow microphone permission in the app settings.';
    }
    if (code.contains('network')) {
      return 'Speech recognition needs a network connection on this phone.';
    }
    if (code.contains('busy')) {
      return 'The microphone is being used by another app. Close it and try again.';
    }
    if (code.contains('no_match') || code.contains('speech_timeout')) {
      return 'I did not hear any words. Wait for the listening vibration, then speak clearly.';
    }
    return 'Speech recognition stopped: ${error.errorMsg}. Please try again.';
  }

  Future<void> _processWords(String words) async {
    if (_handlingResult) return;
    _handlingResult = true;
    _partialResultTimer?.cancel();
    _emptyResultTimer?.cancel();
    await _speech.stop();

    switch (parseVoiceIntent(words)) {
      case VoiceIntent.describeEnvironment:
        await _describeEnvironment();
      case VoiceIntent.cameraStatus:
        await _checkCamera();
      case VoiceIntent.repeat:
        await _respond(
          _lastResponse ?? 'There is no previous response to repeat.',
          remember: false,
        );
      case VoiceIntent.stop:
        await stop();
      case VoiceIntent.help:
        await _respond(
          'You can ask: what is in front of me, is the camera connected, repeat, or stop.',
        );
      case VoiceIntent.unknown:
        await _respond(
          'I did not understand. Try asking: what is in front of me?',
        );
    }
  }

  Future<void> _describeEnvironment() async {
    _setState(
      VoiceAssistantState.processing,
      'Capturing and analyzing the camera image…',
    );
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(pattern: [0, 80, 70, 80]);
    }
    try {
      await _tts.speak(
        'I heard you. Analyzing the camera view. The first request may take up to one minute.',
      );
      _setState(VoiceAssistantState.processing, 'Connecting to the camera…');
      // The dashboard already polls the ESP32-CAM for its preview. Reuse that
      // frame when possible instead of making a competing request; many
      // ESP32-CAM servers can only reliably handle one capture at a time.
      final image =
          await (_imageProvider?.call() ??
              _camera.captureJpeg(captureUrl: ApiConfig.esp32CamCaptureUrl));
      _setState(
        VoiceAssistantState.processing,
        'Image captured. Waiting for the AI description…',
      );
      await (_backendWarmUp ??= _warmBackend());
      final response = await _analysisApi.uploadEnvironmentImage(
        jpegBytes: image,
        languageTag: _localeId,
      );
      final result = (response['result'] as Map?)?.cast<String, dynamic>();
      final rawSummary = result?['summary']?.toString().trim();
      final summary = rawSummary == null
          ? null
          : cleanEnvironmentSummary(rawSummary);
      if (summary == null || summary.isEmpty) {
        await _respond(
          'The image was analyzed, but no description was returned.',
        );
      } else {
        await _respond(summary);
      }
    } catch (error) {
      debugPrint('VOICE ASSISTANT ANALYSIS ERROR: $error');
      await _respond(
        error is TimeoutException
            ? 'The analysis service took too long to respond. Please try once more.'
            : 'I could not analyze the view. Check that the camera and internet connection are available.',
        error: true,
      );
    }
  }

  Future<void> _checkCamera() async {
    _setState(VoiceAssistantState.processing, 'Checking the camera…');
    try {
      await _camera.captureJpeg(captureUrl: ApiConfig.esp32CamCaptureUrl);
      await _respond('The camera is connected and responding.');
    } catch (_) {
      await _respond(
        'The camera is not responding. Check its power, address, and Wi-Fi connection.',
        error: true,
      );
    }
  }

  Future<void> _respond(
    String message, {
    bool error = false,
    bool remember = true,
  }) async {
    if (remember) _lastResponse = message;
    _setState(
      error ? VoiceAssistantState.error : VoiceAssistantState.speaking,
      message,
    );
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: error ? 350 : 80);
    }
    await _tts.setLanguage(_localeId);
    await _tts.speak(message);
    if (!_disposed) {
      _setState(VoiceAssistantState.idle, 'Ask what is in front of you');
    }
  }

  Future<void> stop() async {
    _handlingResult = true;
    await _speech.cancel();
    await _tts.stop();
    _setState(VoiceAssistantState.idle, 'Stopped');
  }

  void _setState(VoiceAssistantState value, String message) {
    _state = value;
    _statusMessage = message;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _partialResultTimer?.cancel();
    _emptyResultTimer?.cancel();
    _volumeChannel.setMethodCallHandler(null);
    _speech.cancel();
    super.dispose();
  }
}
