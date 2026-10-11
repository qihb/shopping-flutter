import 'package:mockito/mockito.dart';

import 'package:my_first_app/features/product/data/models/category_node.dart';
import 'package:my_first_app/features/product/data/models/page_result.dart';
import 'package:my_first_app/features/product/data/models/product_detail.dart';
import 'package:my_first_app/features/product/data/models/product_image.dart';
import 'package:my_first_app/features/product/data/models/product_sku.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';
import 'mocks.mocks.dart';

/// 构造一条测试用的商品摘要数据。
///
/// 默认 mainImage 为空字符串，ProductCard 会直接展示占位图标，
/// 避免 widget 测试环境发起真实网络图片请求。
ProductSummary buildTestProduct(
  int id,
  String name, {
  int categoryId = 1,
  String categoryName = '服饰',
  String subtitle = '测试副标题',
  String mainImage = '',
  double minPrice = 89,
  int sales = 100,
}) {
  return ProductSummary(
    id: id,
    categoryId: categoryId,
    categoryName: categoryName,
    name: name,
    subtitle: subtitle,
    mainImage: mainImage,
    minPrice: minPrice,
    sales: sales,
    status: 1,
    createTime: '2026-01-01 10:00:00',
  );
}

/// 构造一个测试用的分类节点。
CategoryNode buildTestCategory(
  int id,
  String name, {
  int parentId = 0,
  List<CategoryNode> children = const <CategoryNode>[],
}) {
  return CategoryNode(
    id: id,
    parentId: parentId,
    name: name,
    sort: id,
    status: 1,
    children: children,
  );
}

/// 给 [MockProductService] 打桩：商品分页固定返回一页数据。
void stubProductPage(
  MockProductService service, {
  List<ProductSummary> products = const <ProductSummary>[],
  bool hasMore = false,
}) {
  when(service.fetchProducts(
    categoryId: anyNamed('categoryId'),
    keyword: anyNamed('keyword'),
    current: anyNamed('current'),
    size: anyNamed('size'),
  )).thenAnswer(
    (Invocation invocation) async => PageResult<ProductSummary>(
      records: List<ProductSummary>.of(products),
      total: products.length,
      pages: hasMore ? 2 : 1,
      current: 1,
      size: 10,
    ),
  );
}

/// 给 [MockProductService] 打桩：分类树固定返回给定节点。
void stubCategoryTree(MockProductService service, List<CategoryNode> nodes) {
  when(service.fetchCategoryTree()).thenAnswer(
    (_) async => List<CategoryNode>.of(nodes),
  );
}

/// 给 [MockProductService] 打桩：详情固定返回同一条数据。
void stubProductDetail(MockProductService service, ProductDetail detail) {
  when(service.fetchProductDetail(any)).thenAnswer((_) async => detail);
}

/// 构造一条测试用的商品详情数据。
ProductDetail buildTestProductDetail(
  int id,
  String name, {
  int categoryId = 1,
  String categoryName = '服饰',
  String subtitle = '测试副标题',
  String detail = '这是测试商品的说明文字。',
  double minPrice = 89,
  int sales = 100,
  List<ProductSku> skus = const <ProductSku>[],
  List<ProductImage> images = const <ProductImage>[],
}) {
  return ProductDetail(
    id: id,
    categoryId: categoryId,
    categoryName: categoryName,
    name: name,
    subtitle: subtitle,
    mainImage: '',
    detail: detail,
    minPrice: minPrice,
    sales: sales,
    status: 1,
    skus: skus,
    images: images,
  );
}
