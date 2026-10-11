/// 商品列表项（对应后端 `ProductListVO`）。
///
/// 用于首页推荐流、分类页商品列表等只需要概要信息的场景，
/// 详情页使用字段更全的 [ProductDetail]。
class ProductSummary {
  final int id;
  final int categoryId;
  final String categoryName;
  final String name;
  final String subtitle;
  final String mainImage;

  /// 最低销售价（元），列表展示与加购金额计算都用它。
  final double minPrice;
  final int sales;

  /// 上架状态：1-上架，0-下架。
  final int status;
  final String createTime;

  const ProductSummary({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.subtitle,
    required this.mainImage,
    required this.minPrice,
    required this.sales,
    required this.status,
    required this.createTime,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: json['id'] as int? ?? 0,
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      mainImage: json['mainImage'] as String? ?? '',
      // 后端金额是 number，JSON 里可能是 int 也可能是 double，统一转成 double。
      minPrice: (json['minPrice'] as num?)?.toDouble() ?? 0,
      sales: json['sales'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
      createTime: json['createTime'] as String? ?? '',
    );
  }
}
