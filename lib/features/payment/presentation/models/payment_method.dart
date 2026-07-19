/// 支付方式。
///
/// 这里先用 `enum` 收拢支付入口，
/// 可以先理解成网页里“支付宝 / 微信支付”的单选值在 Flutter 里的类型化表达。
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
