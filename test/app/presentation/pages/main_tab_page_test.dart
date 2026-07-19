import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/app/presentation/pages/main_tab_page.dart';
import 'package:my_first_app/features/payment/application/payment_gateway.dart';
import 'package:my_first_app/features/payment/application/payment_service.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

class _RecordingPaymentGateway implements PaymentGateway {
  PaymentRequest? lastRequest;
  final PaymentResult result;

  _RecordingPaymentGateway({required this.result});

  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    lastRequest = request;
    return result;
  }
}

class _SequencedPaymentGateway implements PaymentGateway {
  final List<PaymentResult> results;
  final List<PaymentRequest> requests = <PaymentRequest>[];

  _SequencedPaymentGateway({required this.results});

  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    requests.add(request);

    if (results.isEmpty) {
      throw StateError('没有可用的支付结果可供测试消费');
    }

    return results.removeAt(0);
  }
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

void main() {
  testWidgets('从首页点击分类入口后会切到分类页并选中对应分类', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

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
    await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

    await _addProductToCart(tester);

    expect(find.text('夏季轻运动鞋'), findsOneWidget);
    expect(find.text('EUR 89'), findsWidgets);
    expect(find.text('合计 EUR 89'), findsOneWidget);
  });

  testWidgets('购物车里修改商品数量后会同步更新数量和合计金额', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

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
    final _RecordingPaymentGateway wechatGateway = _RecordingPaymentGateway(
      result: const PaymentResult(
        method: PaymentMethod.wechatPay,
        status: PaymentStatus.success,
        message: '微信支付成功',
      ),
    );
    final _RecordingPaymentGateway alipayGateway = _RecordingPaymentGateway(
      result: const PaymentResult(
        method: PaymentMethod.alipay,
        status: PaymentStatus.success,
        message: '支付宝支付成功',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MainTabPage(
          paymentService: PaymentService(
            gateways: <PaymentMethod, PaymentGateway>{
              PaymentMethod.alipay: alipayGateway,
              PaymentMethod.wechatPay: wechatGateway,
            },
          ),
        ),
      ),
    );

    await _submitFirstOrderWithWechat(tester);

    expect(find.text('微信支付成功'), findsOneWidget);
    expect(find.text('最近订单'), findsOneWidget);
    expect(find.text('订单状态'), findsWidgets);
    expect(find.text('待发货'), findsWidgets);
    expect(find.text('夏季轻运动鞋'), findsOneWidget);
    expect(wechatGateway.lastRequest?.method, PaymentMethod.wechatPay);
    expect(wechatGateway.lastRequest?.orderId, 'ORD-0000001');
    expect(alipayGateway.lastRequest, isNull);
  });

  testWidgets('支付失败后会保留待付款订单并展示失败提示', (WidgetTester tester) async {
    final _RecordingPaymentGateway alipayGateway = _RecordingPaymentGateway(
      result: const PaymentResult(
        method: PaymentMethod.alipay,
        status: PaymentStatus.failure,
        message: '支付宝支付失败',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MainTabPage(
          paymentService: PaymentService(
            gateways: <PaymentMethod, PaymentGateway>{
              PaymentMethod.alipay: alipayGateway,
            },
          ),
        ),
      ),
    );

    await _submitFirstOrder(tester);

    expect(find.text('支付宝支付失败'), findsOneWidget);
    expect(find.text('最近订单'), findsOneWidget);
    expect(find.text('订单状态'), findsWidgets);
    expect(find.text('待付款'), findsWidgets);
    expect(alipayGateway.lastRequest?.method, PaymentMethod.alipay);
    expect(alipayGateway.lastRequest?.orderId, 'ORD-0000001');
  });

  testWidgets('待付款订单可以继续支付并更新为待发货', (WidgetTester tester) async {
    final _SequencedPaymentGateway alipayGateway = _SequencedPaymentGateway(
      results: <PaymentResult>[
        const PaymentResult(
          method: PaymentMethod.alipay,
          status: PaymentStatus.failure,
          message: '支付宝支付失败',
        ),
      ],
    );
    final _SequencedPaymentGateway wechatGateway = _SequencedPaymentGateway(
      results: <PaymentResult>[
        const PaymentResult(
          method: PaymentMethod.wechatPay,
          status: PaymentStatus.success,
          message: '微信补支付成功',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MainTabPage(
          paymentService: PaymentService(
            gateways: <PaymentMethod, PaymentGateway>{
              PaymentMethod.alipay: alipayGateway,
              PaymentMethod.wechatPay: wechatGateway,
            },
          ),
        ),
      ),
    );

    await _submitFirstOrder(tester);

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

    expect(find.text('微信补支付成功'), findsOneWidget);
    expect(find.text('当前还没有待付款的订单'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('待发货'), findsWidgets);
    expect(alipayGateway.requests.single.orderId, 'ORD-0000001');
    expect(wechatGateway.requests.single.orderId, 'ORD-0000001');
    expect(wechatGateway.requests.single.method, PaymentMethod.wechatPay);
  });

  testWidgets('购物车提交订单前会先进入订单确认页并展示地址栏', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

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
    await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

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
    await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

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
    await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

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
    await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

    await _submitFirstOrder(tester);

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
    await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

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
    await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

    await _addProductToCart(tester);

    expect(find.text('已加入购物车：夏季轻运动鞋'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('cart-tab-badge')), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('购物车支持删除单个商品和一键清空', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

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
    expect(find.text('购物车已清空'), findsOneWidget);
  });

  testWidgets('订单记录页可以推进订单状态并同步到我的页面', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

    await _submitFirstOrder(tester);

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
    await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

    await _submitFirstOrder(tester);

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
