import 'package:my_first_app/core/utils/amount_label.dart';

/// 支付结果（对应后端 `PayResultVO`）。
///
/// 服务端当前是模拟网关，一次支付请求直接到位，
/// 因此 `status` 只有「支付成功」一种取值；
/// 接入真实支付渠道后这里会扩展出处理中 / 失败等状态。
class PayResultVO {
  /// 支付状态码：1-支付成功。
  static const int statusSuccess = 1;

  final String orderNo;

  /// 支付金额，单位：元。
  final double amount;
  final int status;

  /// 支付时间。
  final String payTime;

  const PayResultVO({
    required this.orderNo,
    required this.amount,
    required this.status,
    required this.payTime,
  });

  factory PayResultVO.fromJson(Map<String, dynamic> json) {
    return PayResultVO(
      orderNo: json['orderNo'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as int? ?? 0,
      payTime: json['payTime'] as String? ?? '',
    );
  }

  bool get isSuccess => status == statusSuccess;

  String get payAmountLabel => '¥${amountLabel(amount)}';
}
