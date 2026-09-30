import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

/// 支付网关抽象。
///
/// 作为统一支付适配器，页面与订单流程只依赖该接口，
/// 具体走支付宝还是微信由下层实现决定。
abstract class PaymentGateway {
  Future<PaymentResult> pay(PaymentRequest request);
}
