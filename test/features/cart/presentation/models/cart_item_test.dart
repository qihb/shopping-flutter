import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';

void main() {
  test('CartItem.fromProductSummary 会把商品最低价转成展示值和计算值', () {
    final ProductSummary product = ProductSummary(
      id: 1,
      categoryId: 1,
      categoryName: '服饰',
      name: '夏季轻运动鞋',
      subtitle: '透气网面设计，适合通勤和日常轻运动。',
      mainImage: '',
      minPrice: 89.5,
      sales: 100,
      status: 1,
      createTime: '',
    );

    final CartItem item = CartItem.fromProductSummary(product);

    expect(item.name, '夏季轻运动鞋');
    // 金额向下取整，展示与计算保持一致。
    expect(item.priceLabel, '¥89');
    expect(item.unitPrice, 89);
    expect(item.quantity, 1);
  });

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
}
