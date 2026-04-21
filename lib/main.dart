// lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'gen/app_localizations.dart';
import 'models/environment_analysis.dart';
import 'models/snapshots.dart';
import 'screens/dashboard.dart';  
import 'screens/health.dart';
import 'screens/heart_rate_analysis.dart';
import 'screens/live_dashboard.dart';
import 'screens/pulse_live.dart';
import 'screens/settings.dart';
import 'services/esp_pulse_service.dart';
import 'services/firebase_iot_service.dart';
import 'services/iot_service.dart';
import 'services/offline_iot_service.dart';
import 'services/pulse_view_model.dart';
import 'services/locale_provider.dart';
import 'utils/constants.dart';

String? _tryExtractHostname(Object error) {
  final s = error.toString();
  final urlMatch = RegExp(r'https?://([^/\s:]+)', caseSensitive: false).firstMatch(s);
  if (urlMatch != null) return urlMatch.group(1);

  final hostMatch = RegExp(
    r'(?:host(?:name)?|Host)\s*[:=]\s*([^\s\)\],]+)',
    caseSensitive: false,
  ).firstMatch(s);
  if (hostMatch != null) return hostMatch.group(1);

  return null;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  IoTService iotService = OfflineIoTService();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.signInAnonymously();
    iotService = FirebaseIoTService();
  } catch (e, st) {
    final host = _tryExtractHostname(e);
    print('FIREBASE INIT FAILED: $e');
    if (host != null) {
      print('FIREBASE/NETWORK HOSTNAME (best-effort): $host');
    }
    print(st);
  }

  runApp(SmartHealthApp(iotService: iotService));
}

class SmartHealthApp extends StatelessWidget {
  final IoTService iotService;

  const SmartHealthApp({super.key, required this.iotService});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final p = LocaleProvider();
            p.init();
            return p;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(
            iotService: iotService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PulseViewModel(
            service: EspPulseService(
              endpoint: Uri.parse('http://172.20.10.8/'),
            ),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final localeProvider = context.watch<LocaleProvider>();
          return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Health Dashboard',
        locale: localeProvider.locale,
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('my', 'MM'),
          Locale('es', 'ES'),
          Locale('fr', 'FR'),
          Locale('de', 'DE'),
          Locale('zh', 'CN'),
          Locale('ja', 'JP'),
          Locale('ru', 'RU'),
          Locale('ar', 'SA'),
          Locale('hi', 'IN'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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
          HeartRateAnalysisScreen.routeName: (_) => const HeartRateAnalysisScreen(),
          LiveDashboardScreen.routeName: (_) => const LiveDashboardScreen(),
          PulseLiveScreen.routeName: (_) => const PulseLiveScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
        },
      );
        },
      ),
    );
  }
}

/// ViewModel responsible for subscribing to Firebase/Firestore streams and exposing state.
class DashboardViewModel extends ChangeNotifier {
  final IoTService iotService;

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
    print("DASHBOARD VIEWMODEL CREATED");
    print("SUBSCRIBING ENV STREAM NOW");
    _envSub?.cancel();
    _envSub = iotService.streamLatestEnvironmentAnalysis().listen(
      (analysis) {
        print("ENV VM RECEIVED: $analysis");
        _latestEnvironmentAnalysis = analysis;
        notifyListeners();
      },
      onError: (e) {
        print("ENV VM ERROR: $e");
        notifyListeners();
      },
    );
    _startListening();
  }

  void _startListening() {
    if (_isFetching) return;
    _isFetching = true;
    notifyListeners();

    _sensorSub?.cancel();
    _glassesSub?.cancel();

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

