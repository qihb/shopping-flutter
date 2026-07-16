import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';

/// 订单记录。
///
/// 当前阶段先把订单做成一个轻量模型，
/// 目的是让购物车提交后，"我的" 页面有一份明确的数据可以展示。
class OrderRecord {
  final String id;
  final List<CartItem> items;
  final String statusLabel;
  final String totalPriceLabel;

  const OrderRecord({
    required this.id,
    required this.items,
    required this.statusLabel,
    required this.totalPriceLabel,
  });

  /// 这里先直接从购物车条目生成订单，
  /// 可以先把它理解成“下单时把当前购物车快照保存下来”。
  factory OrderRecord.fromCartItems({
    required String id,
    required List<CartItem> items,
  }) {
    final List<CartItem> orderItems = items
        .map((item) => item.copyWith(quantity: item.quantity))
        .toList(growable: false);
    final int totalPrice = orderItems.fold<int>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    return OrderRecord(
      id: id,
      items: orderItems,
      statusLabel: '待发货',
      totalPriceLabel: 'EUR $totalPrice',
    );
  }
}
