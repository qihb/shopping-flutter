import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

/// 支付网关抽象。
///
/// 你可以先把它理解成一个“统一支付适配器”：
/// 页面和订单流程只认这个接口，具体是支付宝还是微信，由下层实现决定。
abstract class PaymentGateway {
  Future<PaymentResult> pay(PaymentRequest request);
}
