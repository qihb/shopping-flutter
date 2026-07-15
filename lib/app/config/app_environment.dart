/// 应用环境枚举。
///
/// 这里把字符串环境值收口成枚举，目的是避免项目里到处直接写 `'dev'`、
/// `'staging'`、`'prod'` 这类魔法字符串。
enum AppEnvironment {
  dev,
  staging,
  prod;

  /// 把 `--dart-define` 传进来的字符串转换成项目内部统一使用的环境枚举。
  ///
  /// 如果传入为空或不在约定范围内，这里会回退到 `dev`，
  /// 这样本地开发时即使没有额外传参，应用也能正常启动。
  static AppEnvironment fromValue(String? value) {
    final String normalizedValue = value?.trim().toLowerCase() ?? '';

    switch (normalizedValue) {
      case 'dev':
      case 'development':
        return AppEnvironment.dev;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      default:
        return AppEnvironment.dev;
    }
  }

  /// 不同环境会映射到不同的本地 JSON 配置文件。
  String get assetPath => 'assets/config/$name.json';
}
