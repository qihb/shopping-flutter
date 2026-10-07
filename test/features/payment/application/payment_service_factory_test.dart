import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/app/config/app_config.dart';
import 'package:my_first_app/app/config/app_environment.dart';
import 'package:my_first_app/features/payment/application/payment_service.dart';
import 'package:my_first_app/features/payment/application/payment_service_factory.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

void main() {
  test('PaymentServiceFactory 在关闭真实支付时返回 Mock 支付服务', () async {
    const AppConfig config = AppConfig(
      environment: AppEnvironment.dev,
      appName: 'My First App Dev',
      apiBaseUrl: 'https://dev-api.example.com',
      enableDebugTools: true,
      enableRealPayment: false,
      alipayAppId: 'mock-alipay-app-id',
      wechatAppId: 'mock-wechat-app-id',
      wechatUniversalLink: 'https://example.com/dev/link/',
    );
    final PaymentService service = PaymentServiceFactory.create(config);

    final PaymentResult result = await service.pay(
      const PaymentRequest(
        orderId: 'ORD-0000001',
        amount: 89,
        title: '夏季轻运动鞋',
        method: PaymentMethod.alipay,
      ),
    );

    expect(result.status, PaymentStatus.success);
    expect(result.message, '支付宝支付成功');
  });

  test('PaymentServiceFactory 在打开真实支付时返回真实网关骨架', () async {
    const AppConfig config = AppConfig(
      environment: AppEnvironment.prod,
      appName: 'My First App',
      apiBaseUrl: 'https://api.example.com',
      enableDebugTools: false,
      enableRealPayment: true,
      alipayAppId: 'real-alipay-app-id',
      wechatAppId: 'real-wechat-app-id',
      wechatUniversalLink: 'https://example.com/prod/link/',
    );
    final PaymentService service = PaymentServiceFactory.create(config);

    final PaymentResult result = await service.pay(
      const PaymentRequest(
        orderId: 'ORD-0000002',
        amount: 299,
        title: '轻弹跑鞋',
        method: PaymentMethod.wechatPay,
      ),
    );

    expect(result.status, PaymentStatus.failure);
    expect(result.message, '微信真实支付暂未启用，请先补齐 AppID、Universal Link 和预支付参数');
  });

  test('PaymentServiceFactory 打开真实支付时支付宝走 tobias 调用链路', () async {
    const AppConfig config = AppConfig(
      environment: AppEnvironment.prod,
      appName: 'My First App',
      apiBaseUrl: 'https://api.example.com',
      enableDebugTools: false,
      enableRealPayment: true,
      alipayAppId: 'real-alipay-app-id',
      wechatAppId: 'real-wechat-app-id',
      wechatUniversalLink: 'https://example.com/prod/link/',
    );
    final PaymentService service = PaymentServiceFactory.create(config);

    final PaymentResult result = await service.pay(
      const PaymentRequest(
        orderId: 'ORD-0000003',
        amount: 199,
        title: '轻弹跑鞋',
        method: PaymentMethod.alipay,
      ),
    );

    // 单元测试环境下没有原生 SDK，平台通道调用会抛 MissingPluginException，
    // 网关应把它收敛为失败结果，说明链路已接入 tobias 调用。
    expect(result.status, PaymentStatus.failure);
    expect(result.message, startsWith('支付宝支付发起失败'));
  });
}
