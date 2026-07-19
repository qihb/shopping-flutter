/// 支付宝 App 支付参数。
///
/// 支付宝客户端真正拉起支付时，核心参数通常就是服务端签名后的 `orderStr`。
/// 这里单独建模型，是为了把“服务端返回结构”从页面和网关逻辑里拆出来。
class AlipayPaymentPayload {
  final String orderString;

  const AlipayPaymentPayload({required this.orderString});

  factory AlipayPaymentPayload.fromJson(Map<String, Object?> json) {
    return AlipayPaymentPayload(
      orderString: json['orderStr'] as String? ?? '',
    );
  }
}
