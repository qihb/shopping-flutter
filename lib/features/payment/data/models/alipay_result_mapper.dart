import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

/// 支付宝 App 支付同步结果码的语义化封装。
///
/// 码值来自支付宝官方文档（https://opendocs.alipay.com/open/204/105301），
/// `tobias` 只做透传，不做任何解释，所以映射关系维护在这一层：
/// 9000 成功、8000 处理中、4000 失败、5000 重复请求、
/// 6001 用户取消、6002 网络出错、6004 结果未知。
enum AlipayResultStatus {
  success('9000', '支付成功'),
  processing('8000', '支付结果处理中'),
  failure('4000', '订单支付失败'),
  duplicated('5000', '重复请求'),
  cancelled('6001', '用户中途取消'),
  networkError('6002', '网络连接出错'),
  unknown('6004', '支付结果未知');

  final String code;
  final String description;

  const AlipayResultStatus(this.code, this.description);

  /// 把 SDK 返回的字符串结果码解析成枚举，无法识别时归为 unknown。
  static AlipayResultStatus fromCode(String? code) {
    return AlipayResultStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => AlipayResultStatus.unknown,
    );
  }

  /// 映射到统一支付状态。
  ///
  /// `processing` 与 `unknown` 表示结果尚未确定，订单不能推进为已支付，
  /// 这里统一按失败返回，由 message 说明实际差异。
  PaymentStatus toPaymentStatus() {
    switch (this) {
      case AlipayResultStatus.success:
        return PaymentStatus.success;
      case AlipayResultStatus.cancelled:
        return PaymentStatus.cancelled;
      case AlipayResultStatus.processing:
      case AlipayResultStatus.failure:
      case AlipayResultStatus.duplicated:
      case AlipayResultStatus.networkError:
      case AlipayResultStatus.unknown:
        return PaymentStatus.failure;
    }
  }
}

/// 把支付宝 SDK 的原始结果 Map 映射成统一支付结果。
///
/// 单独抽成顶层纯函数（不依赖平台通道），
/// 让“SDK 原始结构 -> PaymentResult”的规则可以在单元测试里直接验证。
PaymentResult mapAlipayResult({
  required String orderId,
  required Map<Object?, Object?> raw,
}) {
  final Object? rawStatus = raw['resultStatus'];
  final AlipayResultStatus status = AlipayResultStatus.fromCode(
    rawStatus?.toString(),
  );
  final String memo = raw['memo']?.toString() ?? '';

  return PaymentResult(
    method: PaymentMethod.alipay,
    status: status.toPaymentStatus(),
    message: switch (status) {
      AlipayResultStatus.success => '支付宝支付成功',
      AlipayResultStatus.cancelled => '已取消支付宝支付',
      AlipayResultStatus.processing => '支付宝支付处理中，请稍后在订单记录中确认结果',
      _ => '支付宝支付失败${memo.isEmpty ? '' : '：$memo'}',
    },
    rawResult: <String, Object?>{
      'orderId': orderId,
      'resultStatus': rawStatus,
      'memo': memo,
    },
  );
}
