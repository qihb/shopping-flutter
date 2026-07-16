/// 首页推荐商品的数据结构。
///
/// 先把它提成独立模型，是为了让页面不用同时负责“数据长什么样”和“界面怎么渲染”。
/// 这和前端里把接口返回值抽成单独类型的思路很像，后续接真实接口时也更容易替换。
class HomeRecommendProduct {
  final String name;
  final String description;
  final String priceLabel;
  final String tag;

  const HomeRecommendProduct({
    required this.name,
    required this.description,
    required this.priceLabel,
    required this.tag,
  });
}

/// 推荐商品分页结果。
///
/// 这里用一个轻量结果对象，把“当前页数据”和“是否还有下一页”一起返回，
/// 这样页面就能根据它决定是否继续触发加载。
class HomeRecommendPageResult {
  final List<HomeRecommendProduct> products;
  final bool hasMore;

  const HomeRecommendPageResult({
    required this.products,
    required this.hasMore,
  });
}
