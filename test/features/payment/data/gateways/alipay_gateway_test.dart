import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/payment/application/payment_order_provider.dart';
import 'package:my_first_app/features/payment/data/gateways/alipay_gateway.dart';
import 'package:my_first_app/features/payment/data/mock/mock_payment_order_provider.dart';
import 'package:my_first_app/features/payment/data/models/alipay_payment_payload.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

/// 固定返回同一份支付参数，用于模拟“服务端返回空参数 / 正常参数”的场景。
class _FixedOrderProvider implements PaymentOrderProvider {
  final AlipayPaymentPayload payload;

  const _FixedOrderProvider(this.payload);

  @override
  Future<AlipayPaymentPayload> fetchAlipayPayload(PaymentRequest request) async {
    return payload;
  }
}

/// 直接抛异常的提供方，用于验证网关对取参失败的收敛。
class _ThrowingOrderProvider implements PaymentOrderProvider {
  const _ThrowingOrderProvider();

  @override
  Future<AlipayPaymentPayload> fetchAlipayPayload(PaymentRequest request) async {
    throw Exception('支付服务不可用');
  }
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
      orderProvider: const MockPaymentOrderProvider(),
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
      orderProvider: const MockPaymentOrderProvider(),
      payExecutor: (orderStr) async {
        return <Object?, Object?>{'resultStatus': '6001', 'memo': ''};
      },
    );

    final PaymentResult result = await gateway.pay(_request);

    expect(result.status, PaymentStatus.cancelled);
  });

  test('服务端返回空 orderStr 时收敛为失败结果，不调用 SDK', () async {
    final AlipayGateway gateway = AlipayGateway(
      orderProvider: const _FixedOrderProvider(
        AlipayPaymentPayload(orderString: ''),
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
      orderProvider: const _ThrowingOrderProvider(),
    );

    final PaymentResult result = await gateway.pay(_request);

    expect(result.status, PaymentStatus.failure);
    expect(result.message, startsWith('支付宝支付发起失败'));
  });

  test('SDK 调用抛异常时收敛为失败结果', () async {
    final AlipayGateway gateway = AlipayGateway(
      orderProvider: const MockPaymentOrderProvider(),
      payExecutor: (orderStr) async {
        throw Exception('SDK 未初始化');
      },
    );

    final PaymentResult result = await gateway.pay(_request);

    expect(result.status, PaymentStatus.failure);
    expect(result.message, startsWith('支付宝支付发起失败'));
  });
}
