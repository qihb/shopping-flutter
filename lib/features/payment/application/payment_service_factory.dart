import 'package:my_first_app/app/config/app_config.dart';
import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/features/payment/application/payment_gateway.dart';
import 'package:my_first_app/features/payment/application/payment_service.dart';
import 'package:my_first_app/features/payment/data/gateways/alipay_gateway.dart';
import 'package:my_first_app/features/payment/data/gateways/remote_pay_gateway.dart';
import 'package:my_first_app/features/payment/data/gateways/wechat_pay_gateway.dart';
import 'package:my_first_app/features/payment/data/mock/mock_payment_order_provider.dart';
import 'package:my_first_app/features/payment/data/pay_service.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';

/// 支付服务工厂。
///
/// - `createServerMock()`：支付动作走 spring-shop 的模拟支付网关，
///   当前后端对接阶段的默认实现；
/// - `createReal()`：支付宝已接入 tobias 调用链路，微信仍为占位实现，
///   需要真实商户资质，由 `enableRealPayment` 配置开关启用。
///   两者的支付参数当前都来自本地 Mock 提供方（未签名的测试 orderStr）。
class PaymentServiceFactory {
  const PaymentServiceFactory._();

  static PaymentService create(AppConfig config, {required ApiClient apiClient}) {
    if (config.enableRealPayment) {
      return createReal();
    }

    return createServerMock(apiClient: apiClient);
  }

  /// 服务端模拟网关：两个渠道共用同一个后端模拟支付实现，
  /// 渠道差异要等真实商户参数接入后才生效。
  static PaymentService createServerMock({required ApiClient apiClient}) {
    final RemotePayGateway gateway = RemotePayGateway(
      payService: PayService(apiClient: apiClient),
    );

    return PaymentService(
      gateways: <PaymentMethod, PaymentGateway>{
        PaymentMethod.alipay: gateway,
        PaymentMethod.wechatPay: gateway,
      },
    );
  }

  static PaymentService createReal() {
    return PaymentService(
      gateways: <PaymentMethod, PaymentGateway>{
        // 支付参数来自本地 Mock 提供方，真实 SDK 会因签名校验失败走错误路径。
        PaymentMethod.alipay: AlipayGateway(
          orderProvider: const MockPaymentOrderProvider(),
        ),
        PaymentMethod.wechatPay: const WechatPayGateway(),
      },
    );
  }
}
