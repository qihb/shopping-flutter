import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/payment/data/mock/mock_payment_order_provider.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';

void main() {
  test('Mock provider 生成的 orderStr 携带订单号且无真实签名', () async {
    const MockPaymentOrderProvider provider = MockPaymentOrderProvider();

    final payload = await provider.fetchAlipayPayload(
      const PaymentRequest(
        orderId: 'ORD-0000001',
        amount: 89,
        title: '夏季轻运动鞋',
        method: PaymentMethod.alipay,
      ),
    );

    expect(payload.orderString, contains('out_trade_no=ORD-0000001'));
    expect(payload.orderString, contains('total_amount=89.00'));
    expect(payload.orderString, contains('sign=MOCK_UNSIGNED'));
  });
}
