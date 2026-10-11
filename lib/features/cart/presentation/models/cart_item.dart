import 'package:my_first_app/features/product/data/models/product_summary.dart';

/// 购物车条目。
///
/// 当前阶段先把它做成一个很轻量的数据对象，
/// 负责保存“加入购物车后，购物车页真正需要展示什么”。
class CartItem {
  final String name;
  final String priceLabel;
  final int unitPrice;
  final int quantity;

  const CartItem({
    required this.name,
    required this.priceLabel,
    required this.unitPrice,
    this.quantity = 1,
  });

  /// 直接从商品摘要生成购物车条目，
  /// 金额取商品最低价并向下取整，保持展示与计算一致。
  factory CartItem.fromProductSummary(ProductSummary product) {
    final int unitPrice = product.minPrice.truncate();

    return CartItem(
      name: product.name,
      priceLabel: '¥$unitPrice',
      unitPrice: unitPrice,
    );
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      name: name,
      priceLabel: priceLabel,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  int get totalPrice => unitPrice * quantity;

  String get totalPriceLabel => '¥$totalPrice';
}
