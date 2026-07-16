import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:my_first_app/app/config/app_config.dart';
import 'package:my_first_app/app/config/app_environment.dart';

/// 从 `--dart-define` 和本地 JSON 里组装应用配置。
///
/// 这里的职责只有一个：在应用真正启动前，把“当前环境该用哪份配置”解析出来。
class AppConfigLoader {
  static const String environmentDefineKey = 'APP_ENV';

  final AssetBundle? bundle;

  /// 这个字段主要是为了测试可注入。
  ///
  /// 线上运行时如果不传，就会退回到 `String.fromEnvironment()` 读取编译期参数。
  final String? environmentValue;

  const AppConfigLoader({this.bundle, this.environmentValue});

  Future<AppConfig> load() async {
    final AppEnvironment environment = AppEnvironment.fromValue(
      environmentValue ?? const String.fromEnvironment(environmentDefineKey),
    );
    final AssetBundle assetBundle = bundle ?? rootBundle;
    final String jsonString = await assetBundle.loadString(
      environment.assetPath,
    );
    final Map<String, dynamic> json =
        jsonDecode(jsonString) as Map<String, dynamic>;

    return AppConfig.fromJson(json, environment: environment);
  }
}
