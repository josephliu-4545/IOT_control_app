// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'スマート健康ダッシュボード';

  @override
  String get dashboardTitle => 'スマート健康ダッシュボード';

  @override
  String get pulseTooltip => '脈拍 (ESP8266)';

  @override
  String get liveDashboardTooltip => 'ライブダッシュボード';

  @override
  String get healthDetailsTooltip => '健康の詳細';

  @override
  String get settingsTooltip => '設定';

  @override
  String get heartRate => '心拍数';

  @override
  String get oxygen => '酸素';

  @override
  String get spo2Level => 'SpO₂ レベル';

  @override
  String get wifiSignal => 'Wi‑Fi 信号';

  @override
  String get battery => 'バッテリー';

  @override
  String get solar => 'ソーラー';

  @override
  String get charging => '充電中';

  @override
  String get idle => '待機中';

  @override
  String get harvestingEnergy => 'エネルギー収集中';

  @override
  String get noSolarInput => 'ソーラー入力なし';

  @override
  String get waitingForData => 'データ待機中...';

  @override
  String get stable => '安定';

  @override
  String get systemOnline => 'システムオンライン';

  @override
  String get systemOffline => 'システムオフライン';

  @override
  String get connectingToEsp32Firebase => 'ESP32 / Firebase に接続中...';

  @override
  String get receivingRealtimeSensorData => 'リアルタイムセンサーデータを受信中';

  @override
  String get usingFallbackDummyData => 'フォールバック/ダミーデータを使用中';

  @override
  String get cameraPreviewUnavailable => 'カメラプレビューが利用できません';

  @override
  String get glassesCamera => 'メガネカメラ';

  @override
  String get glassesEnv => 'メガネ環境';

  @override
  String get glassesLink => 'メガネ接続';

  @override
  String get tapToToggleDummy => 'タップして切り替え（ダミー）';

  @override
  String get ambientTemperature => '周囲温度';

  @override
  String get on => 'オン';

  @override
  String get off => 'オフ';

  @override
  String get connected => '接続済み';

  @override
  String get offline => 'オフライン';

  @override
  String get smartGlassesStatus => 'スマートグラスの状態';

  @override
  String get autoSpeakAnalysis => '分析を自動で読み上げ';

  @override
  String get speak => '読み上げ';

  @override
  String get stop => '停止';

  @override
  String get analyzeMyEnvironment => '環境を分析する';

  @override
  String get analyzing => '分析中...';

  @override
  String get environmentImageUploaded => '環境画像を分析用に送信しました。';

  @override
  String failedToAnalyzeEnvironment(String error) {
    return '環境の分析に失敗しました: $error';
  }

  @override
  String get settingsTitle => '設定';

  @override
  String get language => '言語';

  @override
  String get liveHealthDashboardTitle => 'ライブ健康ダッシュボード';

  @override
  String get refresh => '更新';

  @override
  String get failedToLoadDashboard => 'ダッシュボードの読み込みに失敗しました';

  @override
  String get tryAgain => '再試行';

  @override
  String get heartHealthTitle => '心臓の健康';

  @override
  String get realTimeHeartRateTrend => 'リアルタイムの心拍数トレンド';

  @override
  String get pulseRawTitle => '脈拍 (ESP8266 生データ)';

  @override
  String get currentRaw => '現在のRAW';

  @override
  String get waitingForPulseData => 'ESP8266 の脈拍データを待っています...';

  @override
  String get waitingForHeartRateData => '心拍数データを待っています...';

  @override
  String get latestReading => '最新の測定';

  @override
  String flags(String flags) {
    return 'フラグ: $flags';
  }

  @override
  String get summary => '概要';

  @override
  String historyLastN(int count) {
    return '履歴（直近 $count 件）';
  }

  @override
  String get noReadingsYet => 'まだ測定値がありません。';

  @override
  String get noRecentReadings => '最近の測定値はありません。';

  @override
  String get critical => '重大';

  @override
  String get warning => '警告';

  @override
  String get normal => '正常';
}
