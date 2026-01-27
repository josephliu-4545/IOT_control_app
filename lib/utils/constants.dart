// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF050816);
  static const Color cardBackground = Color(0xFF0D1B2A);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color border = Color(0xFF1F2933);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Replace with your real Blynk Cloud configuration when ready.
class BlynkConfig {
  // Set this to false when you are ready to use the real API.
  static const bool useDummyData = true;

  // Blynk Cloud HTTP API.
  static const String baseUrl = 'https://blynk.cloud/external/api';

  // TODO: Put your real Blynk auth token here.
  static const String authToken = 'YOUR_BLYNK_AUTH_TOKEN';

  // Virtual pin mapping.
  static const String pinHeartRate = 'V0';
  static const String pinOxygen = 'V1';
  static const String pinWifi = 'V2';
  static const String pinBattery = 'V3';
  // If you have a pin for solar status, add here (e.g. V4).
}