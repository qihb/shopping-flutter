import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';

/// 支付结果状态。
///
/// 它和订单状态不同：
/// - 支付结果描述的是“一次支付动作”的结果
/// - 订单状态描述的是“一笔订单”当前处于什么阶段
enum PaymentStatus {
  success,
  cancelled,
  failure,
}

/// 支付结果。
///
/// 当前先把不同支付 SDK 的返回值统一收拢到这个模型里，
/// 后续页面层就不需要直接理解支付宝和微信各自的原始字段。
class PaymentResult {
  final PaymentMethod method;
  final PaymentStatus status;
  final String message;
  final Map<String, Object?> rawResult;

  const PaymentResult({
    required this.method,
    required this.status,
    required this.message,
    this.rawResult = const <String, Object?>{},
  });
}
