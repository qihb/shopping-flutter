import 'package:my_first_app/app/config/app_environment.dart';

/// 应用运行时配置。
///
/// 你可以把它理解成“启动后全局可读的一份配置对象”：
/// - 当前是哪个环境
/// - 当前环境对应的应用标题
/// - 接口基础地址是什么
/// - 是否打开调试辅助能力
class AppConfig {
  final AppEnvironment environment;
  final String appName;
  final String apiBaseUrl;
  final bool enableDebugTools;

  const AppConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    required this.enableDebugTools,
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
    );
  }
}
