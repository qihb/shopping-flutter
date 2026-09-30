import 'package:my_first_app/app/app.dart';
import 'package:my_first_app/bootstrap.dart';

/// 应用启动入口。
///
/// 启动流程分三步：
/// 1. 进入 `main()` 方法。
/// 2. 调用 `bootstrap()` 完成启动前准备。
/// 3. 将 `MyApp` 挂载到屏幕上。
///
/// 环境初始化、日志、异常上报等启动逻辑也统一从这里接入。
Future<void> main() async {
  await bootstrap(const MyApp());
}
