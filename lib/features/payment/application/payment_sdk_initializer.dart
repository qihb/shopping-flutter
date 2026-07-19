import 'package:my_first_app/app/config/app_config.dart';

/// 支付 SDK 初始化器。
///
/// 这个抽象的作用是把“应用启动时要不要初始化支付宝 / 微信 SDK”
/// 从 `bootstrap()` 中拆出来，避免启动文件和具体插件直接耦合。
abstract class PaymentSdkInitializer {
  Future<void> initialize(AppConfig config);
}

/// 默认支付 SDK 初始化器。
///
/// 当前阶段先把初始化入口固定住：
/// - 没有真实支付资质时，直接跳过初始化
/// - 后续接入真实微信 SDK 时，可以在这里补 `fluwx.registerApi(...)`
/// - 支付宝通过 `tobias` 发起支付时通常不要求单独初始化，也可以在这里集中放兼容逻辑
class DefaultPaymentSdkInitializer implements PaymentSdkInitializer {
  const DefaultPaymentSdkInitializer();

  @override
  Future<void> initialize(AppConfig config) async {
    if (!config.enableRealPayment) {
      return;
    }

    // 当前项目还没有真实商户参数和可验证的 Universal Link，
    // 所以这里只保留初始化入口，不强行执行真实 SDK 注册。
  }
}
