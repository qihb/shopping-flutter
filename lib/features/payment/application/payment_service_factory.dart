import 'package:my_first_app/app/config/app_config.dart';
import 'package:my_first_app/features/payment/application/payment_gateway.dart';
import 'package:my_first_app/features/payment/application/payment_service.dart';
import 'package:my_first_app/features/payment/data/gateways/alipay_gateway.dart';
import 'package:my_first_app/features/payment/data/gateways/wechat_pay_gateway.dart';
import 'package:my_first_app/features/payment/data/mock/mock_payment_gateway.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';

/// 支付服务工厂。
///
/// 当前先返回一套默认的 Mock 网关映射，
/// 后续拿到真实商户参数后，再在这里切到支付宝 / 微信的真实实现。
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
        PaymentMethod.alipay: const AlipayGateway(),
        PaymentMethod.wechatPay: const WechatPayGateway(),
      },
    );
  }
}
