import 'package:my_first_app/features/payment/application/payment_gateway.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

/// 支付服务。
///
/// 这里单独再包一层服务，是为了把“按支付方式选择网关”的分发逻辑
/// 从页面里抽出来，避免页面直接维护一堆 `if/else`。
class PaymentService {
  final Map<PaymentMethod, PaymentGateway> gateways;

  const PaymentService({required this.gateways});

  Future<PaymentResult> pay(PaymentRequest request) async {
    final PaymentGateway? gateway = gateways[request.method];

    if (gateway == null) {
      return PaymentResult(
        method: request.method,
        status: PaymentStatus.failure,
        message: '未找到对应的支付网关',
      );
    }

    return gateway.pay(request);
  }
}
