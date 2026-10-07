import 'package:my_first_app/app/config/app_config.dart';
import 'package:my_first_app/features/payment/application/payment_gateway.dart';
import 'package:my_first_app/features/payment/application/payment_service.dart';
import 'package:my_first_app/features/payment/data/gateways/alipay_gateway.dart';
import 'package:my_first_app/features/payment/data/gateways/wechat_pay_gateway.dart';
import 'package:my_first_app/features/payment/data/mock/mock_payment_gateway.dart';
import 'package:my_first_app/features/payment/data/mock/mock_payment_order_provider.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';

/// 支付服务工厂。
///
/// `createMock()` 返回纯本地模拟网关，不触碰支付 SDK；
/// `createReal()` 里支付宝已接入 tobias 调用链路，微信仍为占位实现。
/// 两者的支付参数当前都来自本地 Mock 提供方（未签名的测试 orderStr），
/// 接入真实后端后替换 provider 实现即可，网关与上层无需改动。
class PaymentServiceFactory {
  const PaymentServiceFactory._();

  static PaymentService create(AppConfig config) {
    if (config.enableRealPayment) {
      return createReal();
    }

    return createMock();
  }

  static PaymentService createMock() {
    return PaymentService(
      gateways: <PaymentMethod, PaymentGateway>{
        PaymentMethod.alipay: const MockPaymentGateway(),
        PaymentMethod.wechatPay: const MockPaymentGateway(),
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
