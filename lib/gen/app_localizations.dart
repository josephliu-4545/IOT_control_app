import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_my.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('my'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Smart Health Dashboard'**
  String get appTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Health Dashboard'**
  String get dashboardTitle;

  /// No description provided for @pulseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pulse (ESP8266)'**
  String get pulseTooltip;

  /// No description provided for @liveDashboardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Live dashboard'**
  String get liveDashboardTooltip;

  /// No description provided for @healthDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Health details'**
  String get healthDetailsTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get heartRate;

  /// No description provided for @oxygen.
  ///
  /// In en, this message translates to:
  /// **'Oxygen'**
  String get oxygen;

  /// No description provided for @spo2Level.
  ///
  /// In en, this message translates to:
  /// **'SpO₂ level'**
  String get spo2Level;

  /// No description provided for @wifiSignal.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi Signal'**
  String get wifiSignal;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @solar.
  ///
  /// In en, this message translates to:
  /// **'Solar'**
  String get solar;

  /// No description provided for @charging.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get charging;

  /// No description provided for @idle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get idle;

  /// No description provided for @harvestingEnergy.
  ///
  /// In en, this message translates to:
  /// **'Harvesting energy'**
  String get harvestingEnergy;

  /// No description provided for @noSolarInput.
  ///
  /// In en, this message translates to:
  /// **'No solar input'**
  String get noSolarInput;

  /// No description provided for @waitingForData.
  ///
  /// In en, this message translates to:
  /// **'Waiting for data...'**
  String get waitingForData;

  /// No description provided for @stable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stable;

  /// No description provided for @systemOnline.
  ///
  /// In en, this message translates to:
  /// **'System Online'**
  String get systemOnline;

  /// No description provided for @systemOffline.
  ///
  /// In en, this message translates to:
  /// **'System Offline'**
  String get systemOffline;

  /// No description provided for @connectingToEsp32Firebase.
  ///
  /// In en, this message translates to:
  /// **'Connecting to ESP32 / Firebase...'**
  String get connectingToEsp32Firebase;

  /// No description provided for @receivingRealtimeSensorData.
  ///
  /// In en, this message translates to:
  /// **'Receiving real-time sensor data'**
  String get receivingRealtimeSensorData;

  /// No description provided for @usingFallbackDummyData.
  ///
  /// In en, this message translates to:
  /// **'Using fallback / dummy data'**
  String get usingFallbackDummyData;

  /// No description provided for @cameraPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera preview unavailable'**
  String get cameraPreviewUnavailable;

  /// No description provided for @glassesCamera.
  ///
  /// In en, this message translates to:
  /// **'Glasses Camera'**
  String get glassesCamera;

  /// No description provided for @glassesEnv.
  ///
  /// In en, this message translates to:
  /// **'Glasses Env'**
  String get glassesEnv;

  /// No description provided for @glassesLink.
  ///
  /// In en, this message translates to:
  /// **'Glasses Link'**
  String get glassesLink;

  /// No description provided for @tapToToggleDummy.
  ///
  /// In en, this message translates to:
  /// **'Tap to toggle (dummy)'**
  String get tapToToggleDummy;

  /// No description provided for @ambientTemperature.
  ///
  /// In en, this message translates to:
  /// **'Ambient temperature'**
  String get ambientTemperature;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @smartGlassesStatus.
  ///
  /// In en, this message translates to:
  /// **'Smart glasses status'**
  String get smartGlassesStatus;

  /// No description provided for @autoSpeakAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Auto speak analysis'**
  String get autoSpeakAnalysis;

  /// No description provided for @speak.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get speak;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @analyzeMyEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Analyze My Environment'**
  String get analyzeMyEnvironment;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @environmentImageUploaded.
  ///
  /// In en, this message translates to:
  /// **'Environment image uploaded for analysis.'**
  String get environmentImageUploaded;

  /// No description provided for @failedToAnalyzeEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Failed to analyze environment: {error}'**
  String failedToAnalyzeEnvironment(String error);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @liveHealthDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Health Dashboard'**
  String get liveHealthDashboardTitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @failedToLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard'**
  String get failedToLoadDashboard;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @heartHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart Health'**
  String get heartHealthTitle;

  /// No description provided for @realTimeHeartRateTrend.
  ///
  /// In en, this message translates to:
  /// **'Real-time heart rate trend'**
  String get realTimeHeartRateTrend;

  /// No description provided for @pulseRawTitle.
  ///
  /// In en, this message translates to:
  /// **'Pulse (ESP8266 Raw)'**
  String get pulseRawTitle;

  /// No description provided for @currentRaw.
  ///
  /// In en, this message translates to:
  /// **'CURRENT RAW'**
  String get currentRaw;

  /// No description provided for @waitingForPulseData.
  ///
  /// In en, this message translates to:
  /// **'Waiting for ESP8266 pulse data...'**
  String get waitingForPulseData;

  /// No description provided for @waitingForHeartRateData.
  ///
  /// In en, this message translates to:
  /// **'Waiting for heart rate data...'**
  String get waitingForHeartRateData;

  /// No description provided for @latestReading.
  ///
  /// In en, this message translates to:
  /// **'Latest Reading'**
  String get latestReading;

  /// No description provided for @flags.
  ///
  /// In en, this message translates to:
  /// **'Flags: {flags}'**
  String flags(String flags);

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @historyLastN.
  ///
  /// In en, this message translates to:
  /// **'History (last {count})'**
  String historyLastN(int count);

  /// No description provided for @noReadingsYet.
  ///
  /// In en, this message translates to:
  /// **'No readings yet.'**
  String get noReadingsYet;

  /// No description provided for @noRecentReadings.
  ///
  /// In en, this message translates to:
  /// **'No recent readings.'**
  String get noRecentReadings;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'ja',
    'my',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'my':
      return AppLocalizationsMy();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
