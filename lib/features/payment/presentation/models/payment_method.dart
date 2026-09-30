/// 支付方式。
///
/// 使用 `enum` 统一收拢支付入口，避免在页面里散落字符串。
enum PaymentMethod {
  alipay,
  wechatPay,
}

extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.alipay:
        return '支付宝';
      case PaymentMethod.wechatPay:
        return '微信支付';
    }
  }
}
