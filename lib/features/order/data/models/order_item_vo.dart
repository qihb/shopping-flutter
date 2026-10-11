import 'package:my_first_app/core/utils/amount_label.dart';

/// 订单明细（对应后端 `OrderItemVO`）。
///
/// 下单时的商品快照：商品名、规格、单价在订单生成后即固化，
/// 与购物车里的实时数据无关，退换货与对账都以这份快照为准。
class OrderItemVO {
  final int productId;
  final int skuId;

  /// 商品名称快照。
  final String productName;

  /// SKU 规格描述快照，例如「白色 / 42 码」。
  final String skuSpecs;

  /// 商品主图快照。
  final String productImage;

  /// 成交单价快照，单位：元。
  final double price;

  /// 购买数量。
  final int quantity;

  /// 小计金额 = 成交单价 × 购买数量，由后端计算，单位：元。
  final double subtotal;

  const OrderItemVO({
    required this.productId,
    required this.skuId,
    required this.productName,
    required this.skuSpecs,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemVO.fromJson(Map<String, dynamic> json) {
    return OrderItemVO(
      productId: json['productId'] as int? ?? 0,
      skuId: json['skuId'] as int? ?? 0,
      productName: json['productName'] as String? ?? '',
      skuSpecs: json['skuSpecs'] as String? ?? '',
      productImage: json['productImage'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }

  String get priceLabel => '¥${amountLabel(price)}';

  String get subtotalLabel => '¥${amountLabel(subtotal)}';
}
