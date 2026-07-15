import 'package:my_first_app/app/config/app_config.dart';

/// 全局配置存储。
///
/// 当前项目还处在学习和骨架阶段，这里先用最容易理解的静态存储方式：
/// 在 `bootstrap()` 阶段初始化一次，后续页面按需读取。
class AppConfigStore {
  static AppConfig? _instance;

  static AppConfig get instance {
    final AppConfig? config = _instance;

    if (config == null) {
      throw StateError('AppConfigStore 尚未初始化，请先执行 bootstrap()。');
    }

    return config;
  }

  static void setConfig(AppConfig config) {
    _instance = config;
  }

  static void resetForTest() {
    _instance = null;
  }
}
