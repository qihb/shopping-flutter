import 'package:my_first_app/features/payment/application/payment_order_provider.dart';
import 'package:my_first_app/features/payment/data/models/alipay_payment_payload.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';

/// 本地 Mock 的支付参数提供方。
///
/// 在没有真实商户资质的阶段，用它验证“取参数 -> 调 SDK -> 解析结果”链路。
/// 注意：这里生成的 orderStr 没有商户私钥签名，真实支付宝 SDK 会校验失败，
/// 因此只能走通错误回调路径，无法完成真实扣款。
class MockPaymentOrderProvider implements PaymentOrderProvider {
  const MockPaymentOrderProvider();

  @override
  Future<AlipayPaymentPayload> fetchAlipayPayload(PaymentRequest request) async {
    // Mock 参数不参与真实交易，只要求能携带订单号便于问题排查。
    final String totalAmount = request.amount.toStringAsFixed(2);

    return AlipayPaymentPayload(
      orderString: 'mock=true'
          '&out_trade_no=${request.orderId}'
          '&subject=${Uri.encodeComponent(request.title)}'
          '&total_amount=$totalAmount'
          '&sign=MOCK_UNSIGNED',
    );
  }
}
