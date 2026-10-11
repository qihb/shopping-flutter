/// 旧版购物车条目（本地桥接模型）。
///
/// 购物车数据已切换为服务端 `CartItemVO`，本模型只保留一个用途：
/// 作为 `CartNotifier.selectedItems` 到订单确认页的桥接入参，
/// 订单域对接后端接口后会被整体替换。
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

