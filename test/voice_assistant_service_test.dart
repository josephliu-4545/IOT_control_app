import 'package:flutter_test/flutter_test.dart';
import 'package:iot_control_app/services/voice_assistant_service.dart';

void main() {
  group('parseVoiceIntent', () {
    test('recognizes environment-description requests', () {
      expect(
        parseVoiceIntent("What's in front of me?"),
        VoiceIntent.describeEnvironment,
      );
      expect(
        parseVoiceIntent('Describe my surroundings'),
        VoiceIntent.describeEnvironment,
      );
    });

    test('recognizes camera status and assistant controls', () {
      expect(
        parseVoiceIntent('Is the camera connected?'),
        VoiceIntent.cameraStatus,
      );
      expect(parseVoiceIntent('Repeat'), VoiceIntent.repeat);
      expect(parseVoiceIntent('Stop speaking'), VoiceIntent.stop);
      expect(parseVoiceIntent('Help'), VoiceIntent.help);
    });

    test('returns unknown for unsupported requests', () {
      expect(parseVoiceIntent('What time is it?'), VoiceIntent.unknown);
    });
  });
}
