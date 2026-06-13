import 'package:flutter/widgets.dart';

/// 应用启动前的初始化方法。
///
/// 这个文件的作用是把“真正启动 App”之前要做的准备工作单独放出来，
/// 避免 `main.dart` 里塞太多逻辑。
///
/// 目前这里只做了两件事：
/// 1. `WidgetsFlutterBinding.ensureInitialized()`：确保 Flutter 框架先完成初始化。
/// 2. `runApp(app)`：把传进来的根组件显示出来。
///
/// 后面如果你要接入本地存储、读取配置、初始化网络库，也可以继续放在这里。
Future<void> bootstrap(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(app);
}
