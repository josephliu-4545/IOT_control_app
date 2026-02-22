// lib/services/device_command_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceCommandService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DeviceCommandService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> sendAnalyzeEnvironmentCommand({
    String deviceId = 'esp32cam-001',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be authenticated to send device commands.');
    }

    await _firestore.collection('device_commands').add({
      'deviceId': deviceId,
      'command': 'analyze_environment',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'requestedBy': user.uid,
    });
  }
}
