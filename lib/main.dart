// lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'models/environment_analysis.dart';
import 'models/snapshots.dart';
import 'screens/dashboard.dart';
import 'screens/health.dart';
import 'screens/live_dashboard.dart';
import 'services/firebase_iot_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAuth.instance.signInAnonymously();
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
            iotService: FirebaseIoTService(),
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
          LiveDashboardScreen.routeName: (_) => const LiveDashboardScreen(),
        },
      ),
    );
  }
}

/// ViewModel responsible for subscribing to Firebase/Firestore streams and exposing state.
class DashboardViewModel extends ChangeNotifier {
  final FirebaseIoTService iotService;

  SensorSnapshot? _currentSnapshot;
  List<int> _heartRateHistory = [];
  GlassesSnapshot? _glassesSnapshot;
  EnvironmentAnalysis? _latestEnvironmentAnalysis;

  StreamSubscription<SensorSnapshot>? _sensorSub;
  StreamSubscription<GlassesSnapshot>? _glassesSub;
  StreamSubscription<EnvironmentAnalysis>? _envSub;

  SensorSnapshot? get currentSnapshot => _currentSnapshot;

  GlassesSnapshot? get glassesSnapshot => _glassesSnapshot;

  EnvironmentAnalysis? get latestEnvironmentAnalysis =>
      _latestEnvironmentAnalysis;

  List<int> get heartRateHistory => List.unmodifiable(_heartRateHistory);

  bool get isLoading => _currentSnapshot == null && _isFetching;
  bool _isFetching = false;

  DashboardViewModel({
    required this.iotService,
  }) {
    _startListening();
  }

  void _startListening() {
    if (_isFetching) return;
    _isFetching = true;
    notifyListeners();

    _sensorSub?.cancel();
    _glassesSub?.cancel();
    _envSub?.cancel();

    _sensorSub = iotService.streamLatestSensorSnapshot().listen(
      (snapshot) {
        _currentSnapshot = snapshot;
        _appendHeartRate(snapshot.heartRateBpm);
        _isFetching = false;
        notifyListeners();
      },
      onError: (_) {
        _isFetching = false;
        notifyListeners();
      },
    );

    _glassesSub = iotService.streamLatestGlassesSnapshot().listen(
      (snapshot) {
        _glassesSnapshot = snapshot;
        notifyListeners();
      },
      onError: (_) {
        notifyListeners();
      },
    );

    _envSub = iotService.streamLatestEnvironmentAnalysis().listen(
      (analysis) {
        _latestEnvironmentAnalysis = analysis;
        notifyListeners();
      },
      onError: (_) {
        notifyListeners();
      },
    );
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
    _sensorSub?.cancel();
    _glassesSub?.cancel();
    _envSub?.cancel();
    super.dispose();
  }
}

