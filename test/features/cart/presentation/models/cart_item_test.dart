import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';
import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';

void main() {
  test('CartItem.fromHomeRecommendProduct 会把价格文案拆成展示值和计算值', () {
    const HomeRecommendProduct product = HomeRecommendProduct(
      name: '夏季轻运动鞋',
      description: '透气网面设计，适合通勤和日常轻运动。',
      priceLabel: 'EUR 89',
      tag: '上新',
    );

    final CartItem item = CartItem.fromHomeRecommendProduct(product);

    expect(item.name, '夏季轻运动鞋');
    expect(item.priceLabel, 'EUR 89');
    expect(item.unitPrice, 89);
    expect(item.quantity, 1);
  });

  test('CartItem.copyWith 会保留原字段并更新数量与合计金额', () {
    const CartItem item = CartItem(
      name: '极简双肩包',
      priceLabel: 'EUR 129',
      unitPrice: 129,
    );

    final CartItem updatedItem = item.copyWith(quantity: 3);

    expect(updatedItem.name, '极简双肩包');
    expect(updatedItem.priceLabel, 'EUR 129');
    expect(updatedItem.unitPrice, 129);
    expect(updatedItem.quantity, 3);
    expect(updatedItem.totalPrice, 387);
    expect(updatedItem.totalPriceLabel, 'EUR 387');
  });
}
