import 'dart:async';

import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';

/// 首页推荐商品的 mock 数据服务。
///
/// 这里故意保留一个“像接口层一样”的异步方法：
/// - 当前阶段用 `Future.delayed` 模拟网络延迟
/// - 后续有真实接口后，可以继续保留这个方法签名
/// - 到时主要把内部 mock 数据替换成真实请求即可
class HomeRecommendMockService {
  const HomeRecommendMockService();

  /// 当前只是为了说明未来接口会请求哪个资源位，先放一个占位地址。
  ///
  /// 后续如果你接入真实后端，优先替换这里的 URL 和请求实现。
  static const String recommendApiUrl =
      'https://mock.my-first-app.dev/api/home/recommend';

  static const Duration _mockRequestDuration = Duration(milliseconds: 500);

  static const Map<int, List<HomeRecommendProduct>> _mockPages = {
    1: [
      HomeRecommendProduct(
        name: '夏季轻运动鞋',
        description: '透气网面设计，适合通勤和日常轻运动。',
        priceLabel: 'EUR 89',
        tag: '上新',
      ),
      HomeRecommendProduct(
        name: '极简双肩包',
        description: '通勤与短途出行都适合的轻量收纳包。',
        priceLabel: 'EUR 129',
        tag: '人气',
      ),
    ],
    2: [
      HomeRecommendProduct(
        name: '防晒渔夫帽',
        description: '轻薄可折叠，适合夏日通勤和户外出行。',
        priceLabel: 'EUR 39',
        tag: '热卖',
      ),
      HomeRecommendProduct(
        name: '户外随行保温杯',
        description: '双层保温结构，适合露营、办公和日常通勤。',
        priceLabel: 'EUR 49',
        tag: '精选',
      ),
    ],
    3: [
      HomeRecommendProduct(
        name: '柔软家居拖鞋',
        description: '厚底回弹脚感，适合作为居家场景的常备单品。',
        priceLabel: 'EUR 29',
        tag: '回购',
      ),
      HomeRecommendProduct(
        name: '便携折叠收纳箱',
        description: '适合车载和居家使用，收纳零碎物品更整齐。',
        priceLabel: 'EUR 59',
        tag: '新品',
      ),
    ],
  };

  Future<HomeRecommendPageResult> fetchRecommendProducts({
    required int page,
  }) async {
    // `Future.delayed` 可以理解成“先等一会儿再返回结果”。
    // 在没有真实接口时，它很适合模拟网络请求的耗时体验。
    await Future<void>.delayed(_mockRequestDuration);

    final List<HomeRecommendProduct> products = List<HomeRecommendProduct>.of(
      _mockPages[page] ?? const <HomeRecommendProduct>[],
    );

    return HomeRecommendPageResult(
      products: products,
      hasMore: _mockPages.containsKey(page + 1),
    );
  }
}
