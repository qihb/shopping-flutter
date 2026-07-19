import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/payment/data/mock/mock_payment_gateway.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

void main() {
  test('MockPaymentGateway 默认返回对应支付方式的成功结果', () async {
    const PaymentRequest request = PaymentRequest(
      orderId: 'ORD-0000001',
      amount: 89,
      title: '夏季轻运动鞋',
      method: PaymentMethod.alipay,
    );
    final MockPaymentGateway gateway = MockPaymentGateway();

    final PaymentResult result = await gateway.pay(request);

    expect(result.method, PaymentMethod.alipay);
    expect(result.status, PaymentStatus.success);
    expect(result.message, '支付宝支付成功');
    expect(result.rawResult['orderId'], 'ORD-0000001');
  });

  test('MockPaymentGateway 支持返回自定义失败结果', () async {
    const PaymentRequest request = PaymentRequest(
      orderId: 'ORD-0000002',
      amount: 299,
      title: '轻弹跑鞋',
      method: PaymentMethod.wechatPay,
    );
    final MockPaymentGateway gateway = MockPaymentGateway(
      status: PaymentStatus.failure,
      messageBuilder: (paymentRequest) {
        return '${paymentRequest.method.label}暂未开通';
      },
    );

    final PaymentResult result = await gateway.pay(request);

    expect(result.method, PaymentMethod.wechatPay);
    expect(result.status, PaymentStatus.failure);
    expect(result.message, '微信支付暂未开通');
    expect(result.rawResult['title'], '轻弹跑鞋');
  });
}
