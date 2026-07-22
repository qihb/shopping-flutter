import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';

/// 首页推荐商品数据服务。
///
/// 现在改用 `http` 包发起真实网络请求，替换之前的 mock 延迟。
/// 数据来源是 [FakeStore API](https://fakestoreapi.com)，一个免费的电商模拟接口。
///
/// 这样你就可以看到从"mock 本地数据"到"真实 HTTP 请求"的演进过程：
/// - `ApiClient` 统一处理 baseUrl、请求头、异常
/// - 本服务负责把 JSON 响应映射为领域模型
class HomeRecommendService {
  final ApiClient _apiClient;

  /// 每次请求取多少条商品。
  static const int _pageSize = 4;

  HomeRecommendService({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// 获取推荐商品列表（分页）。
  ///
  /// FakeStore API 的 `/products` 不支持 offset/limit，
  /// 所以这里先把全量数据取回来，再在本地做分页截取。
  /// 真实项目里替换成支持分页的接口后，只需改这个方法内部实现。
  Future<HomeRecommendPageResult> fetchRecommendProducts({
    required int page,
  }) async {
    // 首次请求时拉取全量数据并缓存
    final List<dynamic> jsonList = await _fetchAllProducts();
    final List<HomeRecommendProduct> allProducts = jsonList
        .map((json) => _mapProduct(json as Map<String, dynamic>))
        .toList(growable: false);

    final int start = (page - 1) * _pageSize;
    final int end = start + _pageSize;

    final List<HomeRecommendProduct> pageProducts =
        start < allProducts.length
            ? allProducts.sublist(start, end.clamp(0, allProducts.length))
            : <HomeRecommendProduct>[];

    return HomeRecommendPageResult(
      products: pageProducts,
      hasMore: end < allProducts.length,
    );
  }

  List<dynamic>? _cachedProducts;

  /// 发起真实 HTTP GET 请求，获取 FakeStore 全量商品。
  Future<List<dynamic>> _fetchAllProducts() async {
    if (_cachedProducts != null) {
      return _cachedProducts!;
    }

    final dynamic response = await _apiClient.get('/products');

    if (response is! List) {
      throw FormatException('接口返回格式异常，期望数组，实际: ${response.runtimeType}');
    }

    _cachedProducts = response;
    return response;
  }

  /// 把 FakeStore API 的单条商品 JSON 映射为 [HomeRecommendProduct]。
  HomeRecommendProduct _mapProduct(Map<String, dynamic> json) {
    final String title = json['title'] as String? ?? '未命名商品';
    final String description = json['description'] as String? ?? '';
    final num price = json['price'] is num ? json['price'] as num : 0;
    final String category = json['category'] as String? ?? '精选';

    // 中文分类标签映射，让展示更贴近电商场景
    const Map<String, String> categoryLabelMap = <String, String>{
      "men's clothing": '男装',
      "women's clothing": '女装',
      'jewelery': '配饰',
      'electronics': '数码',
    };

    return HomeRecommendProduct(
      name: title,
      description: description,
      priceLabel: 'EUR ${price.toInt()}',
      tag: categoryLabelMap[category] ?? category,
    );
  }
}
