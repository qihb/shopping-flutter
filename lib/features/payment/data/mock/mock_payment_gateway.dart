import 'package:my_first_app/features/payment/application/payment_gateway.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

/// 当前学习阶段使用的 Mock 支付网关。
///
/// 它不会真的拉起支付宝或微信，
/// 而是先用一份可控结果把“下单 -> 支付 -> 回写订单状态”的链路跑通。
class MockPaymentGateway implements PaymentGateway {
  final PaymentStatus status;
  final String Function(PaymentRequest request)? messageBuilder;
  final Duration delay;

  const MockPaymentGateway({
    this.status = PaymentStatus.success,
    this.messageBuilder,
    this.delay = Duration.zero,
  });

  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    return PaymentResult(
      method: request.method,
      status: status,
      message: messageBuilder?.call(request) ?? '${request.method.label}支付成功',
      rawResult: <String, Object?>{
        'orderId': request.orderId,
        'title': request.title,
        'amount': request.amount,
        'mock': true,
      },
    );
  }
}
