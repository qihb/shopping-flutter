/// 商品 SKU（对应后端 `ProductSkuVO`）。
///
/// 一个商品可以有多个 SKU（不同颜色/尺码等规格组合），
/// 详情页选中某个 SKU 后，价格与库存以该 SKU 为准。
class ProductSku {
  final int id;
  final String skuCode;
  final String specs;

  /// 销售价（元）。
  final double price;

  /// 划线价/原价（元），用于详情页价格区对比展示。
  final double originalPrice;
  final int stock;

  /// 状态：1-启用，0-停用。
  final int status;

  const ProductSku({
    required this.id,
    required this.skuCode,
    required this.specs,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.status,
  });

  factory ProductSku.fromJson(Map<String, dynamic> json) {
    return ProductSku(
      id: json['id'] as int? ?? 0,
      skuCode: json['skuCode'] as String? ?? '',
      specs: json['specs'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0,
      stock: json['stock'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
    );
  }
}
