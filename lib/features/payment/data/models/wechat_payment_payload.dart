/// 微信 App 支付预支付参数。
///
/// 你可以先把它理解成“服务端统一下单后，客户端拉起微信支付所需的一组字段”。
/// 这些值必须由服务端返回，客户端不能自己生成签名。
class WechatPaymentPayload {
  final String appId;
  final String partnerId;
  final String prepayId;
  final String packageValue;
  final String nonceStr;
  final String timestamp;
  final String sign;

  const WechatPaymentPayload({
    required this.appId,
    required this.partnerId,
    required this.prepayId,
    required this.packageValue,
    required this.nonceStr,
    required this.timestamp,
    required this.sign,
  });

  factory WechatPaymentPayload.fromJson(Map<String, Object?> json) {
    return WechatPaymentPayload(
      appId: json['appId'] as String? ?? '',
      partnerId: json['partnerId'] as String? ?? '',
      prepayId: json['prepayId'] as String? ?? '',
      packageValue: json['packageValue'] as String? ?? '',
      nonceStr: json['nonceStr'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      sign: json['sign'] as String? ?? '',
    );
  }
}
