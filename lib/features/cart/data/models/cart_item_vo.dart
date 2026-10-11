/// 购物车条目（对应后端 `CartItemVO`）。
///
/// 服务端购物车的最小展示单元：商品快照 + 规格快照 + 勾选 / 失效状态，
/// 购物车页渲染与结算筛选都以它为准。
class CartItemVO {
  /// 购物车条目 id，数量修改 / 删除 / 勾选接口都用它定位。
  final int id;

  /// SKU id，与商品详情页选中的规格一一对应。
  final int skuId;
  final int productId;
  final String productName;
  final String productImage;

  /// SKU 销售规格描述，例如「白色 / 42 码」。
  final String specs;

  /// SKU 现价，单位：元。
  final double price;

  /// 划线价 / 原价，单位：元。
  final double originalPrice;
  final int quantity;
  final bool checked;
  final int stock;

  /// 小计金额 = 单价 × 数量，由后端计算，单位：元。
  final double subtotal;

  /// 是否失效（SKU 已删除 / 停售 / 商品下架），前端据此置灰并禁止结算。
  final bool invalid;

  /// 失效原因说明，失效时展示。
  final String invalidReason;

  const CartItemVO({
    required this.id,
    required this.skuId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.specs,
    required this.price,
    required this.originalPrice,
    required this.quantity,
    required this.checked,
    required this.stock,
    required this.subtotal,
    required this.invalid,
    required this.invalidReason,
  });

  factory CartItemVO.fromJson(Map<String, dynamic> json) {
    return CartItemVO(
      id: json['id'] as int? ?? 0,
      skuId: json['skuId'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] as String? ?? '',
      productImage: json['productImage'] as String? ?? '',
      specs: json['specs'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      checked: json['checked'] as bool? ?? false,
      stock: json['stock'] as int? ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      invalid: json['invalid'] as bool? ?? false,
      invalidReason: json['invalidReason'] as String? ?? '',
    );
  }

  /// 复制并覆盖部分字段，购物车条目变更（数量 / 勾选）后重建对象用。
  CartItemVO copyWith({
    int? id,
    int? skuId,
    int? productId,
    String? productName,
    String? productImage,
    String? specs,
    double? price,
    double? originalPrice,
    int? quantity,
    bool? checked,
    int? stock,
    double? subtotal,
    bool? invalid,
    String? invalidReason,
  }) {
    return CartItemVO(
      id: id ?? this.id,
      skuId: skuId ?? this.skuId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      specs: specs ?? this.specs,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      checked: checked ?? this.checked,
      stock: stock ?? this.stock,
      subtotal: subtotal ?? this.subtotal,
      invalid: invalid ?? this.invalid,
      invalidReason: invalidReason ?? this.invalidReason,
    );
  }

  /// 有效条目才允许勾选与结算。
  bool get isSelectable => !invalid;
}
