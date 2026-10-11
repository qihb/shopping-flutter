import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_result.dart';
import 'package:my_first_app/features/product/data/models/category_node.dart';
import 'package:my_first_app/features/product/data/models/page_result.dart';
import 'package:my_first_app/features/product/data/models/product_detail.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';

/// 商品域数据服务，对接 spring-shop 的前台商品与分类接口。
///
/// 与认证模块 [AuthService] 的分层思路一致：
/// - [ApiClient] 负责 baseUrl、请求头、token 注入和 HTTP 异常
/// - 本服务负责 `Result<T>` 解包和 JSON 到模型的映射
class ProductService {
  final ApiClient _apiClient;

  ProductService({required this._apiClient});

  /// 分页查询上架商品。
  ///
  /// [categoryId] / [keyword] 为可选筛选，只有非 null 时才拼进 query；
  /// current / size 是后端必填的分页参数，始终携带。
  Future<PageResult<ProductSummary>> fetchProducts({
    int? categoryId,
    String? keyword,
    int current = 1,
    int size = 10,
  }) async {
    final dynamic data = parseResultData(
      await _apiClient.get(
        '/api/products',
        queryParameters: <String, String>{
          if (categoryId != null) 'categoryId': '$categoryId',
          // 空 keyword 没有筛选意义，同样不携带。
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          'current': '$current',
          'size': '$size',
        },
      ),
    );

    return PageResult<ProductSummary>.fromJson(
      data as Map<String, dynamic>,
      ProductSummary.fromJson,
    );
  }

  /// 查询商品详情（含 SKU 与图片列表）。
  Future<ProductDetail> fetchProductDetail(int id) async {
    final dynamic data =
        parseResultData(await _apiClient.get('/api/products/$id'));
    return ProductDetail.fromJson(data as Map<String, dynamic>);
  }

  /// 获取启用分类的树形结构，首页快捷入口与分类页左侧导航共用。
  Future<List<CategoryNode>> fetchCategoryTree() async {
    final dynamic data =
        parseResultData(await _apiClient.get('/api/categories/tree'));
    final List<dynamic> jsonList = data as List<dynamic>? ?? <dynamic>[];

    return jsonList
        .map((node) => CategoryNode.fromJson(node as Map<String, dynamic>))
        .toList(growable: false);
  }
}
