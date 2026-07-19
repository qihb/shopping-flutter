import 'package:my_first_app/features/payment/application/payment_gateway.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

/// 支付宝真实支付网关骨架。
///
/// 后续拿到服务端生成的 `orderStr` 后，
/// 这里会接入 `tobias` 发起真实支付。
class AlipayGateway implements PaymentGateway {
  const AlipayGateway();

  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    return PaymentResult(
      method: PaymentMethod.alipay,
      status: PaymentStatus.failure,
      message: '支付宝真实支付暂未启用，请先补齐服务端 orderStr 和商户配置',
      rawResult: <String, Object?>{
        'orderId': request.orderId,
        'placeholder': true,
      },
    );
  }
}
