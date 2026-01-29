// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'screens/dashboard.dart';
import 'screens/health.dart';
import 'services/blynk_service.dart';
import 'utils/constants.dart';

void main() {
  runApp(const SmartHealthApp());
}

class SmartHealthApp extends StatelessWidget {
  const SmartHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(
            blynkService: BlynkService(),
            refreshInterval: const Duration(seconds: 2),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Health Dashboard',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          textTheme: baseTextTheme,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentBlue,
            secondary: AppColors.accentGreen,
            surface: AppColors.background,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
          ),
        ),
        initialRoute: DashboardScreen.routeName,
        routes: {
          DashboardScreen.routeName: (_) => const DashboardScreen(),
          HealthScreen.routeName: (_) => const HealthScreen(),
        },
      ),
    );
  }
}

/// ViewModel responsible for polling the BlynkService and exposing state.
class DashboardViewModel extends ChangeNotifier {
  final BlynkService blynkService;
  final Duration refreshInterval;
  Timer? _timer;

  SensorSnapshot? _currentSnapshot;
  List<int> _heartRateHistory = [];
  GlassesSnapshot? _glassesSnapshot;

  SensorSnapshot? get currentSnapshot => _currentSnapshot;

  GlassesSnapshot? get glassesSnapshot => _glassesSnapshot;

  List<int> get heartRateHistory => List.unmodifiable(_heartRateHistory);

  bool get isLoading => _currentSnapshot == null && _isFetching;
  bool _isFetching = false;

  DashboardViewModel({
    required this.blynkService,
    required this.refreshInterval,
  }) {
    _startPolling();
  }

  void _startPolling() {
    _fetchOnce();
    _timer?.cancel();
    _timer = Timer.periodic(refreshInterval, (_) => _fetchOnce());
  }

  Future<void> _fetchOnce() async {
    if (_isFetching) return;
    _isFetching = true;
    notifyListeners();

    final snapshot = await blynkService.fetchSensorSnapshot();
    final glasses = await blynkService.fetchGlassesSnapshot();

    _currentSnapshot = snapshot;
    _glassesSnapshot = glasses;
    _appendHeartRate(snapshot.heartRateBpm);

    _isFetching = false;
    notifyListeners();
  }

  void _appendHeartRate(int value) {
    _heartRateHistory = [..._heartRateHistory, value];
    if (_heartRateHistory.length > 60) {
      // Keep last 60 points (~2 minutes at 2s interval).
      _heartRateHistory =
          _heartRateHistory.sublist(_heartRateHistory.length - 60);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}