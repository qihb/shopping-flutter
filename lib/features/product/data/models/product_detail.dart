import 'package:my_first_app/features/product/data/models/product_image.dart';
import 'package:my_first_app/features/product/data/models/product_sku.dart';

/// 商品详情（对应后端 `ProductDetailVO`）。
///
/// 相比列表用的 [ProductSummary]，多了富文本详情、SKU 列表与图片列表，
/// 用于商品详情页展示与加购。
class ProductDetail {
  final int id;
  final int categoryId;
  final String categoryName;
  final String name;
  final String subtitle;
  final String mainImage;

  /// 商品详情富文本（后端可能是 HTML），展示层自行降级为纯文本。
  final String detail;
  final double minPrice;
  final int sales;

  /// 上架状态：1-上架，0-下架。
  final int status;
  final List<ProductSku> skus;
  final List<ProductImage> images;

  const ProductDetail({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.subtitle,
    required this.mainImage,
    required this.detail,
    required this.minPrice,
    required this.sales,
    required this.status,
    required this.skus,
    required this.images,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final List<dynamic> jsonSkus =
        json['skus'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> jsonImages =
        json['images'] as List<dynamic>? ?? <dynamic>[];

    return ProductDetail(
      id: json['id'] as int? ?? 0,
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      mainImage: json['mainImage'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      minPrice: (json['minPrice'] as num?)?.toDouble() ?? 0,
      sales: json['sales'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
      skus: jsonSkus
          .map((sku) => ProductSku.fromJson(sku as Map<String, dynamic>))
          .toList(growable: false),
      images: jsonImages
          .map((image) => ProductImage.fromJson(image as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
