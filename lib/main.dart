import 'package:my_first_app/app/app.dart';
import 'package:my_first_app/bootstrap.dart';

/// 应用启动入口。
///
/// 你可以把它理解成整个 Flutter 项目的“总开关”：
/// 1. 先进入 `main()` 方法。
/// 2. 再调用 `bootstrap()` 做启动前准备。
/// 3. 最后把 `MyApp` 挂载到屏幕上。
///
/// 后续如果你要加环境初始化、日志、异常上报，通常也是从这里开始。
Future<void> main() async {
  await bootstrap(const MyApp());
}
