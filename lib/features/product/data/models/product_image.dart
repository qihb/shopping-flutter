/// 商品图片（对应后端 `ProductImageVO`）。
class ProductImage {
  final int id;
  final String imageUrl;

  /// 排序值，越小越靠前，轮播按它决定图片顺序。
  final int sort;

  const ProductImage({
    required this.id,
    required this.imageUrl,
    required this.sort,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      sort: json['sort'] as int? ?? 0,
    );
  }
}
