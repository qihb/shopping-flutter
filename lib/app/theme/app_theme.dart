import 'package:flutter/material.dart';

/// 应用主题集中管理文件。
///
/// 当你以后想统一修改颜色、按钮样式、字体风格时，
/// 优先改这里，而不是去每个页面里单独改。
class AppTheme {
  const AppTheme._();

  /// 浅色主题。
  ///
  /// 这是当前应用默认使用的主题配置。
  /// 后面如果需要深色模式，可以继续新增 `dark()` 方法。
  static ThemeData light() {
    // 通过种子色快速生成一套 Material 3 配色方案。
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: CircleBorder(),
      ),
    );
  }
}
