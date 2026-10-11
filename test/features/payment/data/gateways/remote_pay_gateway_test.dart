import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/payment/data/gateways/remote_pay_gateway.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';
import '../../../../helpers/mocks.mocks.dart';
import '../../../../helpers/stub_helpers.dart';

void main() {
  // 每个用例独立一套 Mock 支付服务，互不影响。
  (RemotePayGateway, MockPayService) buildGateway() {
    final MockPayService payService = MockPayService();
    return (
      RemotePayGateway(payService: payService),
      payService,
    );
  }

  const PaymentRequest request = PaymentRequest(
    orderId: 'ORD-0000001',
    method: PaymentMethod.alipay,
  );

  test('支付成功时翻译为统一成功结果并携带订单号与支付时间', () async {
    final (RemotePayGateway gateway, MockPayService payService) = buildGateway();
    stubPayResult(
      payService,
      buildTestPayResultVO('ORD-0000001', payTime: '2026-01-01 10:05:00'),
    );

    final PaymentResult result = await gateway.pay(request);

    expect(result.method, PaymentMethod.alipay);
    expect(result.status, PaymentStatus.success);
    expect(result.message, '支付成功');
    expect(result.rawResult['orderNo'], 'ORD-0000001');
    expect(result.rawResult['payTime'], '2026-01-01 10:05:00');
  });

  test('业务失败时透出后端提示', () async {
    final (RemotePayGateway gateway, MockPayService payService) = buildGateway();
    when(payService.mockPay(any))
        .thenThrow(ApiException(message: '订单状态不支持支付'));

    final PaymentResult result = await gateway.pay(request);

    expect(result.status, PaymentStatus.failure);
    expect(result.message, '订单状态不支持支付');
  });

  test('网络异常等非业务错误收敛为统一的失败提示', () async {
    final (RemotePayGateway gateway, MockPayService payService) = buildGateway();
    when(payService.mockPay(any)).thenThrow(Exception('connection reset'));

    final PaymentResult result = await gateway.pay(request);

    expect(result.status, PaymentStatus.failure);
    expect(result.message, '支付失败，请稍后重试');
  });
}
