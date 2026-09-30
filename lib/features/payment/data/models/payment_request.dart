import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';

/// 发起支付时需要的请求数据。
///
/// 生产环境中这些数据通常来自创建订单后由服务端返回的预支付参数，
/// 当前保留最小字段，后续再补齐支付宝 `orderStr` 与微信预支付参数。
class PaymentRequest {
  final String orderId;
  final int amount;
  final String title;
  final PaymentMethod method;
  final Map<String, Object?> payload;

  const PaymentRequest({
    required this.orderId,
    required this.amount,
    required this.title,
    required this.method,
    this.payload = const <String, Object?>{},
  });
}
