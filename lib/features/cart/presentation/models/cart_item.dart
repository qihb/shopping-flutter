import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';

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

  /// 这里直接从首页推荐商品生成购物车条目，
  /// 目的是先把“详情页加入购物车”这条链路打通。
  factory CartItem.fromHomeRecommendProduct(HomeRecommendProduct product) {
    return CartItem(
      name: product.name,
      priceLabel: product.priceLabel,
      unitPrice: _parseUnitPrice(product.priceLabel),
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

  String get totalPriceLabel => 'EUR $totalPrice';

  static int _parseUnitPrice(String priceLabel) {
    final RegExpMatch? match = RegExp(r'(\d+)$').firstMatch(priceLabel);

    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }
}
