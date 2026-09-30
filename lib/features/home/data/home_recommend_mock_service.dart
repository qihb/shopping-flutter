import 'dart:async';

import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';

/// 首页推荐商品的 mock 数据服务。
///
/// 对外提供与真实接口一致的异步方法签名：
/// - 当前用 `Future.delayed` 模拟网络延迟
/// - 接入真实接口后保留该方法签名，仅替换内部数据源
class HomeRecommendMockService {
  /// 推荐资源位接口地址，当前为占位值。
  ///
  /// 接入真实后端时优先替换此 URL 与请求实现。
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

  const HomeRecommendMockService();

  Future<HomeRecommendPageResult> fetchRecommendProducts({
    required int page,
  }) async {
    // 通过 `Future.delayed` 模拟网络请求耗时，便于在未接入真实接口时联调。
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
