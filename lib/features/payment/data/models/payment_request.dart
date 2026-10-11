import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';

/// 发起支付时需要的请求数据。
///
/// 服务端模拟网关阶段，订单号即支付凭据，金额与标题由服务端按订单计算，
/// 这两个字段保留为可选，供真实支付渠道（需要预支付参数）接入后使用。
class PaymentRequest {
  final String orderId;
  final PaymentMethod method;

  /// 展示用金额（元），服务端以订单实际金额为准。
  final int amount;

  /// 展示用商品标题。
  final String title;
  final Map<String, Object?> payload;

  const PaymentRequest({
    required this.orderId,
    required this.method,
    this.amount = 0,
    this.title = '',
    this.payload = const <String, Object?>{},
  });
}
