/// 金额展示文案格式化。
///
/// 服务端金额以「元」为单位用 `double` 下发（如 89.0、19.9），
/// 直接插值会出现 "¥89.0" 这类多余的小数部分：
/// - 整数金额省略小数点：89.0 → "89"
/// - 非整数金额保留两位小数：19.9 → "19.90"
///
/// 订单、订单明细与支付结果三个模型共用这一口径，保证展示一致。
String amountLabel(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toInt().toString();
  }
  return amount.toStringAsFixed(2);
}
