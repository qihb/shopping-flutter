import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/app/presentation/pages/main_tab_page.dart';
import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/cart/application/cart_notifier.dart';
import 'package:my_first_app/features/order/application/order_notifier.dart';
import 'package:my_first_app/features/payment/application/payment_gateway.dart';
import 'package:my_first_app/features/payment/application/payment_service.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';
import 'package:my_first_app/features/profile/application/address_notifier.dart';
import 'package:my_first_app/features/profile/application/settings_notifier.dart';
import 'package:my_first_app/features/profile/presentation/models/user_address.dart';
import '../../../helpers/mocks.mocks.dart';
import '../../../helpers/stub_helpers.dart';

/// 创建默认未登录的登录态管理：token 存取走 Mock，restoreSession 后处于未登录态。
AuthNotifier _buildAuthNotifier() {
  final MockAuthService authService = MockAuthService();
  final MockTokenStore tokenStore = MockTokenStore();
  when(tokenStore.readToken()).thenAnswer((_) async => null);
  return AuthNotifier(
    authService: authService,
    tokenStore: tokenStore,
  )..restoreSession();
}

/// 创建已打桩的推荐服务：按页返回 [HomeRecommendMockService] 的固定数据。
MockHomeRecommendService _buildRecommendService() {
  final MockHomeRecommendService service = MockHomeRecommendService();
  stubRecommendFromMockData(service);
  return service;
}

/// 创建默认支付成功的网关（用于不需要自定义支付结果的测试）。
MockPaymentGateway _buildSuccessGateway() {
  final MockPaymentGateway gateway = MockPaymentGateway();
  when(gateway.pay(any)).thenAnswer(
    (_) async => const PaymentResult(
      method: PaymentMethod.alipay,
      status: PaymentStatus.success,
      message: '支付成功',
    ),
  );
  return gateway;
}

/// 创建返回固定结果的网关（用于验证支付参数或失败提示）。
MockPaymentGateway _buildGatewayWithResult(PaymentResult result) {
  final MockPaymentGateway gateway = MockPaymentGateway();
  when(gateway.pay(any)).thenAnswer((_) async => result);
  return gateway;
}

/// 创建按队列依次返回结果的网关（用于模拟失败后重试等序列场景）。
MockPaymentGateway _buildSequencedGateway(List<PaymentResult> results) {
  final MockPaymentGateway gateway = MockPaymentGateway();
  final List<PaymentResult> queue = List<PaymentResult>.of(results);
  when(gateway.pay(any)).thenAnswer((_) async {
    if (queue.isEmpty) {
      throw StateError('没有可用的支付结果可供测试消费');
    }
    return queue.removeAt(0);
  });
  return gateway;
}

/// 提取网关收到过的支付请求（单次调用场景）。
PaymentRequest _capturedPayRequest(MockPaymentGateway gateway) {
  return verify(gateway.pay(captureAny)).captured.single as PaymentRequest;
}

/// 创建一个用于测试的 MainTabPage Provider 包装。
///
/// `MainTabPage` 通过 Provider 树间接获取状态，
/// 测试时需要把各个 Notifier 注入进去。
Widget _buildTestApp({
  PaymentService? paymentService,
}) {
  final PaymentService service = paymentService ??
      PaymentService(
        gateways: <PaymentMethod, PaymentGateway>{
          PaymentMethod.alipay: _buildSuccessGateway(),
          PaymentMethod.wechatPay: _buildSuccessGateway(),
        },
      );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthNotifier>(
        create: (_) => _buildAuthNotifier(),
      ),
      ChangeNotifierProvider<CartNotifier>(create: (_) => CartNotifier()),
      ChangeNotifierProvider<OrderNotifier>(
        create: (_) => OrderNotifier(paymentService: service),
      ),
      ChangeNotifierProvider<AddressNotifier>(
        create: (_) => AddressNotifier(
          initialAddresses: const <UserAddress>[
            UserAddress(
              recipientName: 'Qi Hai Bing',
              phone: '138 0000 1234',
              cityLabel: '上海市',
              detailAddress: '浦东新区张江高科',
              isDefault: true,
            ),
            UserAddress(
              recipientName: 'Qi Hai Bing',
              phone: '138 0000 5678',
              cityLabel: '上海市',
              detailAddress: '徐汇区漕河泾开发区',
            ),
          ],
        ),
      ),
      ChangeNotifierProvider<SettingsNotifier>(create: (_) => SettingsNotifier()),
    ],
    child: MaterialApp(
      home: MainTabPage(
        recommendService: _buildRecommendService(),
      ),
    ),
  );
}

Future<void> _addProductToCart(
  WidgetTester tester, {
  String productName = '夏季轻运动鞋',
}) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text(productName),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text(productName).first);
  await tester.pumpAndSettle();

  await tester.scrollUntilVisible(
    find.text('加入购物车'),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();

  await tester.tap(
    find.byKey(const ValueKey<String>('product-detail-add-to-cart')),
  );
  await tester.pumpAndSettle();
}

Future<void> _submitFirstOrder(WidgetTester tester) async {
  await _addProductToCart(tester);
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey<String>('cart-submit-order')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey<String>('cart-submit-order')));
  await tester.pumpAndSettle();
  expect(find.text('订单确认'), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey<String>('order-confirm-pay')));
  await tester.pumpAndSettle();
}

Future<void> _submitFirstOrderWithWechat(WidgetTester tester) async {
  await _addProductToCart(tester);
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey<String>('cart-submit-order')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey<String>('cart-submit-order')));
  await tester.pumpAndSettle();
  expect(find.text('订单确认'), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey<String>('payment-method-wechat')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey<String>('order-confirm-pay')));
  await tester.pumpAndSettle();
}

/// 点击底部导航切换到"我的"Tab。
Future<void> _switchToProfileTab(WidgetTester tester) async {
  await tester.tap(find.text('我的'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('从首页点击分类入口后会切到分类页并选中对应分类', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('鞋靴'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('鞋靴').first);
    await tester.pumpAndSettle();

    expect(find.text('轻弹跑鞋'), findsOneWidget);
    expect(find.text('城市通勤板鞋'), findsOneWidget);
  });

  testWidgets('从商品详情加入购物车后会在购物车页看到对应商品', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _addProductToCart(tester);

    expect(find.text('夏季轻运动鞋'), findsOneWidget);
    expect(find.text('EUR 89'), findsWidgets);
    expect(find.text('合计 EUR 89'), findsOneWidget);
  });

  testWidgets('购物车里修改商品数量后会同步更新数量和合计金额', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _addProductToCart(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('cart-increase-夏季轻运动鞋')),
    );
    await tester.pumpAndSettle();

    expect(find.text('数量 x2'), findsOneWidget);
    expect(find.text('合计 EUR 178'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('cart-decrease-夏季轻运动鞋')),
    );
    await tester.pumpAndSettle();

    expect(find.text('数量 x1'), findsOneWidget);
    expect(find.text('合计 EUR 89'), findsOneWidget);
  });

  testWidgets('从购物车进入订单确认页后支付成功并在我的页面显示订单', (WidgetTester tester) async {
    final MockPaymentGateway wechatGateway = _buildGatewayWithResult(
      const PaymentResult(
        method: PaymentMethod.wechatPay,
        status: PaymentStatus.success,
        message: '微信支付成功',
      ),
    );
    final MockPaymentGateway alipayGateway = _buildGatewayWithResult(
      const PaymentResult(
        method: PaymentMethod.alipay,
        status: PaymentStatus.success,
        message: '支付宝支付成功',
      ),
    );

    await tester.pumpWidget(
      _buildTestApp(
        paymentService: PaymentService(
          gateways: <PaymentMethod, PaymentGateway>{
            PaymentMethod.alipay: alipayGateway,
            PaymentMethod.wechatPay: wechatGateway,
          },
        ),
      ),
    );

    await _submitFirstOrderWithWechat(tester);

    await _switchToProfileTab(tester);
    expect(find.text('最近订单'), findsOneWidget);
    expect(find.text('订单状态'), findsWidgets);
    expect(find.text('待发货'), findsWidgets);
    expect(find.text('夏季轻运动鞋'), findsOneWidget);

    // 校验微信网关收到的支付请求，且支付宝网关未被调用。
    final PaymentRequest wechatRequest = _capturedPayRequest(wechatGateway);
    expect(wechatRequest.method, PaymentMethod.wechatPay);
    expect(wechatRequest.orderId, 'ORD-0000001');
    verifyNever(alipayGateway.pay(any));
  });

  testWidgets('支付失败后会保留待付款订单并展示失败提示', (WidgetTester tester) async {
    final MockPaymentGateway alipayGateway = _buildGatewayWithResult(
      const PaymentResult(
        method: PaymentMethod.alipay,
        status: PaymentStatus.failure,
        message: '支付宝支付失败',
      ),
    );

    await tester.pumpWidget(
      _buildTestApp(
        paymentService: PaymentService(
          gateways: <PaymentMethod, PaymentGateway>{
            PaymentMethod.alipay: alipayGateway,
          },
        ),
      ),
    );

    await _submitFirstOrder(tester);

    expect(find.text('支付宝支付失败'), findsOneWidget);
    await _switchToProfileTab(tester);
    expect(find.text('最近订单'), findsOneWidget);
    expect(find.text('订单状态'), findsWidgets);
    expect(find.text('待付款'), findsWidgets);

    final PaymentRequest alipayRequest = _capturedPayRequest(alipayGateway);
    expect(alipayRequest.method, PaymentMethod.alipay);
    expect(alipayRequest.orderId, 'ORD-0000001');
  });

  testWidgets('待付款订单可以继续支付并更新为待发货', (WidgetTester tester) async {
    final MockPaymentGateway alipayGateway = _buildSequencedGateway(
      <PaymentResult>[
        const PaymentResult(
          method: PaymentMethod.alipay,
          status: PaymentStatus.failure,
          message: '支付宝支付失败',
        ),
      ],
    );
    final MockPaymentGateway wechatGateway = _buildSequencedGateway(
      <PaymentResult>[
        const PaymentResult(
          method: PaymentMethod.wechatPay,
          status: PaymentStatus.success,
          message: '微信补支付成功',
        ),
      ],
    );

    await tester.pumpWidget(
      _buildTestApp(
        paymentService: PaymentService(
          gateways: <PaymentMethod, PaymentGateway>{
            PaymentMethod.alipay: alipayGateway,
            PaymentMethod.wechatPay: wechatGateway,
          },
        ),
      ),
    );

    await _submitFirstOrder(tester);

    await _switchToProfileTab(tester);
    expect(find.text('支付宝支付失败'), findsOneWidget);
    expect(find.text('待付款'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey<String>('profile-order-status-待付款')),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前筛选：待付款'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('order-repay-ORD-0000001')),
    );
    await tester.pumpAndSettle();

    expect(find.text('订单确认'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('payment-method-wechat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('order-confirm-pay')));
    await tester.pumpAndSettle();

    expect(find.text('当前还没有待付款的订单'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('待发货'), findsWidgets);

    // 首次支付宝失败和补付微信成功各自收到一笔请求。
    final PaymentRequest alipayRequest = _capturedPayRequest(alipayGateway);
    expect(alipayRequest.orderId, 'ORD-0000001');
    final PaymentRequest wechatRequest = _capturedPayRequest(wechatGateway);
    expect(wechatRequest.orderId, 'ORD-0000001');
    expect(wechatRequest.method, PaymentMethod.wechatPay);
  });

  testWidgets('购物车提交订单前会先进入订单确认页并展示地址栏', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _addProductToCart(tester);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('cart-submit-order')));
    await tester.pumpAndSettle();

    expect(find.text('订单确认'), findsOneWidget);
    expect(find.text('收货地址'), findsOneWidget);
    expect(find.text('Qi Hai Bing'), findsOneWidget);
    expect(find.text('上海市浦东新区张江高科'), findsOneWidget);
    expect(find.text('确认支付'), findsOneWidget);
  });

  testWidgets('我的页面切换基础设置后会更新当前状态文案', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('profile-setting-notification')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('消息通知: 已开启'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('profile-setting-notification')),
    );
    await tester.pumpAndSettle();

    expect(find.text('消息通知: 已关闭'), findsOneWidget);
  });

  testWidgets('我的页面可以进入地址管理页并展示地址列表', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('profile-address-manage-entry')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('profile-address-manage-entry')),
    );
    await tester.pumpAndSettle();

    expect(find.text('地址管理'), findsOneWidget);
    expect(find.text('上海市浦东新区张江高科'), findsOneWidget);
    expect(find.text('上海市徐汇区漕河泾开发区'), findsOneWidget);
  });

  testWidgets('修改默认地址后订单确认页会展示新的收货地址', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('profile-address-manage-entry')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('profile-address-manage-entry')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('address-set-default-上海市徐汇区漕河泾开发区'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('默认地址 上海市徐汇区漕河泾开发区'), findsOneWidget);

    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();

    await _addProductToCart(tester);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('cart-submit-order')));
    await tester.pumpAndSettle();

    expect(find.text('上海市徐汇区漕河泾开发区'), findsOneWidget);
  });

  testWidgets('点击每个订单状态后都会跳转到订单记录页', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _submitFirstOrder(tester);

    await _switchToProfileTab(tester);
    final List<String> orderStatusLabels = <String>['待付款', '待发货', '待收货', '已完成'];

    for (final String statusLabel in orderStatusLabels) {
      await tester.tap(
        find.byKey(ValueKey<String>('profile-order-status-$statusLabel')),
      );
      await tester.pumpAndSettle();

      expect(find.text('订单记录'), findsOneWidget);
      expect(find.text('当前筛选：$statusLabel'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('从分类页进入详情并加入购物车后会在购物车看到商品', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    await tester.tap(find.text('分类'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('鞋靴'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('category-product-轻弹跑鞋')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('category-product-轻弹跑鞋')),
    );
    await tester.pumpAndSettle();

    expect(find.text('商品详情'), findsOneWidget);
    expect(find.text('轻弹跑鞋'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('加入购物车'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('product-detail-add-to-cart')),
    );
    await tester.pumpAndSettle();

    expect(find.text('轻弹跑鞋'), findsOneWidget);
    expect(find.text('合计 EUR 299'), findsOneWidget);
  });

  testWidgets('加入购物车后会显示提示并更新购物车角标', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _addProductToCart(tester);

    expect(find.text('已加入购物车：夏季轻运动鞋'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('cart-tab-badge')), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('购物车支持删除单个商品和一键清空', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _addProductToCart(tester, productName: '夏季轻运动鞋');
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分类'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('鞋靴'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('category-product-轻弹跑鞋')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('category-product-轻弹跑鞋')),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('加入购物车'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('product-detail-add-to-cart')),
    );
    await tester.pumpAndSettle();

    expect(find.text('夏季轻运动鞋'), findsOneWidget);
    expect(find.text('轻弹跑鞋'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('cart-delete-夏季轻运动鞋')),
    );
    await tester.pumpAndSettle();

    expect(find.text('夏季轻运动鞋'), findsNothing);
    expect(find.text('轻弹跑鞋'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('cart-clear-all')));
    await tester.pumpAndSettle();

    expect(find.text('购物车还是空的'), findsOneWidget);
  });

  testWidgets('订单记录页可以推进订单状态并同步到我的页面', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _submitFirstOrder(tester);

    await _switchToProfileTab(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('profile-order-status-待发货')),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前筛选：待发货'), findsOneWidget);
    expect(find.text('下一步: 待收货'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('order-advance-ORD-0000001')),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前还没有待发货的订单'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('待收货'), findsWidgets);
    expect(find.text('订单状态'), findsWidgets);
  });

  testWidgets('点击订单记录卡片后会进入订单详情页', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _submitFirstOrder(tester);

    await _switchToProfileTab(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('profile-order-status-待发货')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('order-record-card-ORD-0000001')),
    );
    await tester.pumpAndSettle();

    expect(find.text('订单详情'), findsOneWidget);
    expect(find.text('订单编号 ORD-0000001'), findsOneWidget);
    expect(find.text('状态 待发货'), findsOneWidget);
    expect(find.text('商品清单'), findsOneWidget);
  });
}
