import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';
import 'package:my_first_app/features/order/presentation/models/order_record.dart';
import 'package:my_first_app/features/profile/presentation/models/user_address.dart';

void main() {
  test('OrderRecord.fromCartItems 会复制购物车快照并计算订单合计', () {
    const List<CartItem> items = <CartItem>[
      CartItem(
        name: '夏季轻运动鞋',
        priceLabel: 'EUR 89',
        unitPrice: 89,
        quantity: 2,
      ),
      CartItem(
        name: '极简双肩包',
        priceLabel: 'EUR 129',
        unitPrice: 129,
      ),
    ];

    final OrderRecord order = OrderRecord.fromCartItems(
      id: 'ORD-0000001',
      items: items,
      shippingAddress: const UserAddress(
        recipientName: 'Qi Hai Bing',
        phone: '138 0000 1234',
        cityLabel: '上海市',
        detailAddress: '浦东新区张江高科',
      ),
    );

    expect(order.id, 'ORD-0000001');
    expect(order.status, OrderStatus.pendingPayment);
    expect(order.statusLabel, '待付款');
    expect(order.totalPrice, 307);
    expect(order.totalPriceLabel, 'EUR 307');
    expect(order.shippingAddressLabel, '上海市浦东新区张江高科');
    expect(order.items, isNot(same(items)));
    expect(order.items.first.quantity, 2);
  });

  test('OrderRecord.advanceStatus 会按最小流程推进订单状态', () {
    const OrderRecord order = OrderRecord(
      id: 'ORD-0000002',
      items: <CartItem>[],
      status: OrderStatus.pendingShipment,
      totalPrice: 89,
      shippingAddress: UserAddress(
        recipientName: 'Qi Hai Bing',
        phone: '138 0000 1234',
        cityLabel: '上海市',
        detailAddress: '徐汇区漕河泾开发区',
      ),
    );

    final OrderRecord nextOrder = order.advanceStatus();
    final OrderRecord completedOrder = nextOrder.advanceStatus();

    expect(nextOrder.status, OrderStatus.pendingDelivery);
    expect(nextOrder.nextStatusLabel, '已完成');
    expect(completedOrder.status, OrderStatus.completed);
    expect(completedOrder.canAdvanceStatus, isFalse);
    expect(completedOrder.advanceStatus(), same(completedOrder));
  });

  test('OrderRecord.learningSamples 会提供不同状态的学习型示例订单', () {
    final List<OrderStatus> statuses = OrderRecord.learningSamples
        .map((order) => order.status)
        .toList(growable: false);

    expect(statuses, contains(OrderStatus.pendingPayment));
    expect(statuses, contains(OrderStatus.pendingShipment));
    expect(statuses, contains(OrderStatus.completed));
  });
}
