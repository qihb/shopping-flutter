import 'package:my_first_app/app/config/app_environment.dart';

/// 应用运行时配置。
///
/// 启动后全局可读的配置对象，包含：
/// - 当前环境
/// - 当前环境对应的应用标题
/// - 接口基础地址
/// - 是否启用调试辅助能力
class AppConfig {
  final AppEnvironment environment;
  final String appName;
  final String apiBaseUrl;
  final bool enableDebugTools;
  final bool enableRealPayment;
  final String alipayAppId;
  final String wechatAppId;
  final String wechatUniversalLink;

  const AppConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    required this.enableDebugTools,
    required this.enableRealPayment,
    required this.alipayAppId,
    required this.wechatAppId,
    required this.wechatUniversalLink,
  });

  /// 把 JSON 配置转换成 Dart 对象。
  ///
  /// JSON 更适合做“环境差异化数据”，
  /// Dart 对象更适合在代码里安全地读取这些字段。
  factory AppConfig.fromJson(
    Map<String, dynamic> json, {
    required AppEnvironment environment,
  }) {
    return AppConfig(
      environment: environment,
      appName: json['appName'] as String? ?? 'My First App',
      apiBaseUrl: json['apiBaseUrl'] as String? ?? '',
      enableDebugTools: json['enableDebugTools'] as bool? ?? false,
      enableRealPayment: json['enableRealPayment'] as bool? ?? false,
      alipayAppId: json['alipayAppId'] as String? ?? '',
      wechatAppId: json['wechatAppId'] as String? ?? '',
      wechatUniversalLink: json['wechatUniversalLink'] as String? ?? '',
    );
  }
}
