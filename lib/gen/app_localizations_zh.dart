// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '智能健康仪表盘';

  @override
  String get dashboardTitle => '智能健康仪表盘';

  @override
  String get pulseTooltip => '脉搏 (ESP8266)';

  @override
  String get liveDashboardTooltip => '实时仪表盘';

  @override
  String get healthDetailsTooltip => '健康详情';

  @override
  String get settingsTooltip => '设置';

  @override
  String get heartRate => '心率';

  @override
  String get oxygen => '血氧';

  @override
  String get spo2Level => 'SpO₂ 水平';

  @override
  String get wifiSignal => 'Wi‑Fi 信号';

  @override
  String get battery => '电池';

  @override
  String get solar => '太阳能';

  @override
  String get charging => '充电中';

  @override
  String get idle => '空闲';

  @override
  String get harvestingEnergy => '采集能量';

  @override
  String get noSolarInput => '无太阳能输入';

  @override
  String get waitingForData => '等待数据...';

  @override
  String get stable => '稳定';

  @override
  String get systemOnline => '系统在线';

  @override
  String get systemOffline => '系统离线';

  @override
  String get connectingToEsp32Firebase => '正在连接 ESP32 / Firebase...';

  @override
  String get receivingRealtimeSensorData => '正在接收实时传感器数据';

  @override
  String get usingFallbackDummyData => '正在使用备用/模拟数据';

  @override
  String get cameraPreviewUnavailable => '相机预览不可用';

  @override
  String get glassesCamera => '眼镜相机';

  @override
  String get glassesEnv => '眼镜环境';

  @override
  String get glassesLink => '眼镜连接';

  @override
  String get tapToToggleDummy => '点击切换（模拟）';

  @override
  String get ambientTemperature => '环境温度';

  @override
  String get on => '开';

  @override
  String get off => '关';

  @override
  String get connected => '已连接';

  @override
  String get offline => '离线';

  @override
  String get smartGlassesStatus => '智能眼镜状态';

  @override
  String get autoSpeakAnalysis => '自动朗读分析';

  @override
  String get speak => '朗读';

  @override
  String get stop => '停止';

  @override
  String get analyzeMyEnvironment => '分析我的环境';

  @override
  String get analyzing => '分析中...';

  @override
  String get environmentImageUploaded => '环境图片已上传用于分析。';

  @override
  String failedToAnalyzeEnvironment(String error) {
    return '环境分析失败：$error';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get language => '语言';

  @override
  String get liveHealthDashboardTitle => '实时健康仪表盘';

  @override
  String get refresh => '刷新';

  @override
  String get failedToLoadDashboard => '无法加载仪表盘';

  @override
  String get tryAgain => '重试';

  @override
  String get heartHealthTitle => '心脏健康';

  @override
  String get realTimeHeartRateTrend => '实时心率趋势';

  @override
  String get pulseRawTitle => '脉搏 (ESP8266 原始)';

  @override
  String get currentRaw => '当前原始值';

  @override
  String get waitingForPulseData => '正在等待 ESP8266 脉搏数据...';

  @override
  String get waitingForHeartRateData => '正在等待心率数据...';

  @override
  String get latestReading => '最新读数';

  @override
  String flags(String flags) {
    return '标记：$flags';
  }

  @override
  String get summary => '汇总';

  @override
  String historyLastN(int count) {
    return '历史记录（最近 $count 条）';
  }

  @override
  String get noReadingsYet => '暂无读数。';

  @override
  String get noRecentReadings => '没有最近读数。';

  @override
  String get critical => '严重';

  @override
  String get warning => '警告';

  @override
  String get normal => '正常';
}
