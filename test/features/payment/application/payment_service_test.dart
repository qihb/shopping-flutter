import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/features/payment/application/payment_gateway.dart';
import 'package:my_first_app/features/payment/application/payment_service.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';
import '../../../helpers/mocks.mocks.dart';

void main() {
  test('PaymentService 会根据支付方式把请求分发到对应网关', () async {
    final MockPaymentGateway alipayGateway = MockPaymentGateway();
    when(alipayGateway.pay(any)).thenAnswer(
      (_) async => const PaymentResult(
        method: PaymentMethod.alipay,
        status: PaymentStatus.success,
        message: '支付宝支付成功',
      ),
    );
    final MockPaymentGateway wechatGateway = MockPaymentGateway();
    when(wechatGateway.pay(any)).thenAnswer(
      (_) async => const PaymentResult(
        method: PaymentMethod.wechatPay,
        status: PaymentStatus.success,
        message: '微信支付成功',
      ),
    );
    final PaymentService service = PaymentService(
      gateways: <PaymentMethod, PaymentGateway>{
        PaymentMethod.alipay: alipayGateway,
        PaymentMethod.wechatPay: wechatGateway,
      },
    );
    const PaymentRequest request = PaymentRequest(
      orderId: 'ORD-0000001',
      amount: 89,
      title: '夏季轻运动鞋',
      method: PaymentMethod.wechatPay,
    );

    final PaymentResult result = await service.pay(request);

    expect(result.method, PaymentMethod.wechatPay);
    expect(result.status, PaymentStatus.success);
    // 微信网关收到原样请求，支付宝网关不应被调用。
    final PaymentRequest captured =
        verify(wechatGateway.pay(captureAny)).captured.single as PaymentRequest;
    expect(captured, same(request));
    verifyNever(alipayGateway.pay(any));
  });

  test('PaymentService 在找不到对应网关时会返回失败结果', () async {
    final PaymentService service = PaymentService(
      gateways: const <PaymentMethod, PaymentGateway>{},
    );
    const PaymentRequest request = PaymentRequest(
      orderId: 'ORD-0000002',
      amount: 299,
      title: '轻弹跑鞋',
      method: PaymentMethod.alipay,
    );

    final PaymentResult result = await service.pay(request);

    expect(result.method, PaymentMethod.alipay);
    expect(result.status, PaymentStatus.failure);
    expect(result.message, '未找到对应的支付网关');
  });
}
