import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';
import 'package:my_first_app/features/order/presentation/pages/order_confirm_page.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/profile/presentation/models/user_address.dart';

void main() {
  testWidgets('订单确认页会展示支付方式并支持切换到微信支付', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderConfirmPage(
          items: const <CartItem>[
            CartItem(
              name: '夏季轻运动鞋',
              priceLabel: '¥89',
              unitPrice: 89,
            ),
          ],
          address: const UserAddress(
            recipientName: 'Qi Hai Bing',
            phone: '138 0000 1234',
            cityLabel: '上海市',
            detailAddress: '浦东新区张江高科',
          ),
          onConfirmPayment: (_) async {},
        ),
      ),
    );

    expect(find.text('支付方式'), findsOneWidget);
    expect(find.text('支付宝'), findsOneWidget);
    expect(find.text('微信支付'), findsOneWidget);

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
          items: const <CartItem>[
            CartItem(
              name: '轻弹跑鞋',
              priceLabel: '¥299',
              unitPrice: 299,
            ),
          ],
          address: const UserAddress(
            recipientName: 'Qi Hai Bing',
            phone: '138 0000 1234',
            cityLabel: '上海市',
            detailAddress: '浦东新区张江高科',
          ),
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
