import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/features/payment/data/gateways/alipay_gateway.dart';
// 生产侧的生产 Mock 与 mockito 生成的 MockPaymentOrderProvider 同名，
// 这里加前缀区分：`prod_mock.MockPaymentOrderProvider` 是业务里的生产 Mock。
import 'package:my_first_app/features/payment/data/mock/mock_payment_order_provider.dart'
    as prod_mock;
import 'package:my_first_app/features/payment/data/models/alipay_payment_payload.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';
import '../../../../helpers/mocks.mocks.dart';

/// 创建返回固定支付参数的提供方，用于模拟“服务端返回空参数 / 正常参数”的场景。
MockPaymentOrderProvider buildFixedOrderProvider(AlipayPaymentPayload payload) {
  final MockPaymentOrderProvider provider = MockPaymentOrderProvider();
  when(provider.fetchAlipayPayload(any)).thenAnswer((_) async => payload);
  return provider;
}

/// 创建直接抛异常的提供方，用于验证网关对取参失败的收敛。
MockPaymentOrderProvider buildThrowingOrderProvider() {
  final MockPaymentOrderProvider provider = MockPaymentOrderProvider();
  when(provider.fetchAlipayPayload(any)).thenThrow(Exception('支付服务不可用'));
  return provider;
}

const PaymentRequest _request = PaymentRequest(
  orderId: 'ORD-0000001',
  amount: 89,
  title: '夏季轻运动鞋',
  method: PaymentMethod.alipay,
);

void main() {
  test('SDK 返回 9000 时网关输出支付成功结果', () async {
    final AlipayGateway gateway = AlipayGateway(
      orderProvider: const prod_mock.MockPaymentOrderProvider(),
      payExecutor: (orderStr) async {
        expect(orderStr, contains('out_trade_no=ORD-0000001'));
        return <Object?, Object?>{'resultStatus': '9000', 'memo': ''};
      },
    );

    final PaymentResult result = await gateway.pay(_request);

    expect(result.status, PaymentStatus.success);
    expect(result.message, '支付宝支付成功');
  });

  test('SDK 返回 6001 时网关输出用户取消结果', () async {
    final AlipayGateway gateway = AlipayGateway(
      orderProvider: const prod_mock.MockPaymentOrderProvider(),
      payExecutor: (orderStr) async {
        return <Object?, Object?>{'resultStatus': '6001', 'memo': ''};
      },
    );

    final PaymentResult result = await gateway.pay(_request);

    expect(result.status, PaymentStatus.cancelled);
  });

  test('服务端返回空 orderStr 时收敛为失败结果，不调用 SDK', () async {
    final AlipayGateway gateway = AlipayGateway(
      orderProvider: buildFixedOrderProvider(
        const AlipayPaymentPayload(orderString: ''),
      ),
      payExecutor: (orderStr) async {
        fail('不应调用支付宝 SDK');
      },
    );

    final PaymentResult result = await gateway.pay(_request);

    expect(result.status, PaymentStatus.failure);
    expect(result.message, '未获取到支付宝支付参数，请检查支付服务配置');
  });

  test('取参抛异常时收敛为失败结果而不是向上抛出', () async {
    final AlipayGateway gateway = AlipayGateway(
      orderProvider: buildThrowingOrderProvider(),
    );

    final PaymentResult result = await gateway.pay(_request);

    expect(result.status, PaymentStatus.failure);
    expect(result.message, startsWith('支付宝支付发起失败'));
  });

  test('SDK 调用抛异常时收敛为失败结果', () async {
    final AlipayGateway gateway = AlipayGateway(
      orderProvider: const prod_mock.MockPaymentOrderProvider(),
      payExecutor: (orderStr) async {
        throw Exception('SDK 未初始化');
      },
    );

    final PaymentResult result = await gateway.pay(_request);

    expect(result.status, PaymentStatus.failure);
    expect(result.message, startsWith('支付宝支付发起失败'));
  });
}
