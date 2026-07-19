import 'package:flutter/widgets.dart';
import 'package:my_first_app/app/config/app_config_loader.dart';
import 'package:my_first_app/app/config/app_config_store.dart';
import 'package:my_first_app/features/payment/application/payment_sdk_initializer.dart';

/// 应用启动前的初始化方法。
///
/// 这个文件的作用是把“真正启动 App”之前要做的准备工作单独放出来，
/// 避免 `main.dart` 里塞太多逻辑。
///
/// 目前这里只做了两件事：
/// 1. `WidgetsFlutterBinding.ensureInitialized()`：确保 Flutter 框架先完成初始化。
/// 2. 读取当前环境对应的 JSON 配置，并保存到全局配置存储中。
/// 3. 预留支付 SDK 初始化入口，避免后续把原生 SDK 初始化散落到页面层。
/// 4. `runApp(app)`：把传进来的根组件显示出来。
///
/// 后面如果你要接入本地存储、读取配置、初始化网络库，也可以继续放在这里。
Future<void> bootstrap(
  Widget app, {
  AppConfigLoader? configLoader,
  PaymentSdkInitializer? paymentSdkInitializer,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppConfigLoader loader = configLoader ?? const AppConfigLoader();
  final config = await loader.load();
  AppConfigStore.setConfig(config);
  final PaymentSdkInitializer initializer =
      paymentSdkInitializer ?? const DefaultPaymentSdkInitializer();
  await initializer.initialize(config);
  runApp(app);
}
