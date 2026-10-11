import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/cart/data/models/cart_item_vo.dart';
import 'package:my_first_app/features/order/presentation/pages/order_confirm_page.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/profile/data/models/address_vo.dart';
import '../../../../helpers/stub_helpers.dart';

void main() {
  // 订单确认页直接消费服务端购物车条目与地址数据。
  final List<CartItemVO> items = <CartItemVO>[buildTestCartItem(1, '夏季轻运动鞋')];
  final AddressVO address = buildTestAddress(1);

  testWidgets('订单确认页展示地址与商品信息并支持切换支付方式', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderConfirmPage(
          items: items,
          address: address,
          onConfirmPayment: (_) async {},
        ),
      ),
    );

    expect(find.text('收货地址'), findsOneWidget);
    expect(find.text('Qi Hai Bing'), findsOneWidget);
    expect(find.text('13800001234'), findsOneWidget);
    expect(find.text('上海市浦东新区张江高科'), findsOneWidget);

    expect(find.text('商品信息'), findsOneWidget);
    expect(find.text('夏季轻运动鞋'), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);
    expect(find.text('¥89'), findsOneWidget);
    expect(find.text('应付 ¥89'), findsOneWidget);

    expect(find.text('支付方式'), findsOneWidget);
    expect(find.text('支付宝'), findsOneWidget);
    expect(find.text('微信支付'), findsOneWidget);

    // 默认选中支付宝，可以切换到微信支付。
    final RadioListTile<dynamic> alipayTile = tester.widget<RadioListTile<dynamic>>(
      find.byKey(const ValueKey<String>('payment-method-alipay')),
    );
    expect(alipayTile.checked, isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('payment-method-wechat')));
    await tester.pumpAndSettle();

    final RadioListTile<dynamic> wechatTile = tester.widget<RadioListTile<dynamic>>(
      find.byKey(const ValueKey<String>('payment-method-wechat')),
    );
    expect(wechatTile.checked, isTrue);
  });

  testWidgets('订单确认页确认支付时会回传当前选中的支付方式', (WidgetTester tester) async {
    PaymentMethod? confirmedMethod;

    await tester.pumpWidget(
      MaterialApp(
        home: OrderConfirmPage(
          items: items,
          address: address,
          onConfirmPayment: (method) async {
            confirmedMethod = method;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('payment-method-wechat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('order-confirm-pay')));
    await tester.pumpAndSettle();

    expect(confirmedMethod, PaymentMethod.wechatPay);
  });
}
