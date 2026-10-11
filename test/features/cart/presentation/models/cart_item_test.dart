import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';

void main() {
  test('CartItem.copyWith 会保留原字段并更新数量与合计金额', () {
    const CartItem item = CartItem(
      name: '极简双肩包',
      priceLabel: '¥129',
      unitPrice: 129,
    );

    final CartItem updatedItem = item.copyWith(quantity: 3);

    expect(updatedItem.name, '极简双肩包');
    expect(updatedItem.priceLabel, '¥129');
    expect(updatedItem.unitPrice, 129);
    expect(updatedItem.quantity, 3);
    expect(updatedItem.totalPrice, 387);
    expect(updatedItem.totalPriceLabel, '¥387');
  });

  test('CartItem.totalPrice 按单价 × 数量计算', () {
    const CartItem item = CartItem(
      name: '夏季轻运动鞋',
      priceLabel: '¥89',
      unitPrice: 89,
      quantity: 2,
    );

    expect(item.totalPrice, 178);
    expect(item.totalPriceLabel, '¥178');
  });
}
