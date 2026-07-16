import 'package:flutter/material.dart';

import 'package:my_first_app/features/home/data/home_recommend_mock_service.dart';
import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';
import 'package:my_first_app/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:my_first_app/features/home/presentation/widgets/recommend_product_card.dart';
import 'package:my_first_app/features/home/presentation/pages/product_detail_page.dart';

/// 首页页面。
///
/// 这个页面现在不再自己包 `Scaffold`，
/// 因为外层已经有一个统一承载底部导航的主页面。
///
/// 当前首页先做成一个“电商首页草图”：
/// - 顶部搜索入口
/// - 活动横幅
/// - 分类快捷入口
/// - 推荐商品列表与滚动加载
///
/// 这样做的目的不是一次把业务做完，
/// 而是先把最常见的首页区块和布局方式串起来，方便后续继续迭代。
///
/// 这里改成 `StatefulWidget`，
/// 是因为“推荐商品是否还在加载、已经加载到第几页”都属于页面里的本地状态。
class HomePage extends StatefulWidget {
  static const List<_HomeCategoryItem> _categories = [
    _HomeCategoryItem(label: '服饰', icon: Icons.checkroom_outlined),
    _HomeCategoryItem(label: '鞋靴', icon: Icons.hiking_outlined),
    _HomeCategoryItem(label: '箱包', icon: Icons.work_outline),
    _HomeCategoryItem(label: '数码', icon: Icons.devices_outlined),
    _HomeCategoryItem(label: '家居', icon: Icons.chair_outlined),
    _HomeCategoryItem(label: '食品', icon: Icons.local_grocery_store_outlined),
  ];

  /// 首页分类入口点击后的回调。
  ///
  /// 这里把点击结果往外抛，是为了让外层主页面决定：
  /// 当前是切 Tab、打开新页，还是做别的跳转承接。
  final ValueChanged<String>? onCategoryTap;
  final ValueChanged<HomeRecommendProduct>? onAddToCart;

  const HomePage({super.key, this.onCategoryTap, this.onAddToCart});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final HomeRecommendMockService _recommendMockService =
      const HomeRecommendMockService();

  final List<HomeRecommendProduct> _products = <HomeRecommendProduct>[];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _isRequestInFlight = false;
  bool _hasMore = true;
  int _nextPage = 1;
  int _bannerRefreshVersion = 0;

  @override
  void initState() {
    super.initState();
    // `ScrollController` 可以拿到滚动位置。
    // 这里监听它的变化，就能在用户接近底部时触发“加载下一页”。
    _scrollController.addListener(_handleScroll);
    _loadMoreProducts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final ScrollPosition position = _scrollController.position;

    // `extentAfter` 表示当前滚动位置下方还剩多少可滚动内容。
    // 用它比直接比较总高度更直观，也更适合表达“快到底部时再请求下一页”。
    if (position.extentAfter <= 24) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isRequestInFlight || !_hasMore) {
      return;
    }

    final bool isFirstPage = _nextPage == 1;
    _isRequestInFlight = true;

    if (!isFirstPage) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    final HomeRecommendPageResult pageResult = await _recommendMockService
        .fetchRecommendProducts(page: _nextPage);

    if (!mounted) {
      _isRequestInFlight = false;
      return;
    }

    setState(() {
      _products.addAll(pageResult.products);
      _hasMore = pageResult.hasMore;
      _nextPage += 1;
      _isInitialLoading = false;
      _isLoadingMore = false;
      _isRequestInFlight = false;
    });
  }

  Future<void> _refreshHomeContent() async {
    if (_isRequestInFlight) {
      return;
    }

    // 下拉刷新通常表示“重新请求当前首页数据源”。
    // 这里把推荐区分页状态和轮播图区块一起重置，效果会更接近真实电商首页。
    setState(() {
      _products.clear();
      _isInitialLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _nextPage = 1;
      _bannerRefreshVersion += 1;
    });

    await _loadMoreProducts();
  }

  void _openProductDetail(HomeRecommendProduct product) {
    // `Navigator.push` 会把详情页压到当前页面栈顶。
    // 对 Flutter 初学者来说，可以先把它理解成“从列表进入一个新页面”。
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          product: product,
          onAddToCart: () => widget.onAddToCart?.call(product),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // `RefreshIndicator` 是 Flutter 里常见的下拉刷新组件。
      // 它很适合包在一个可滚动区域外层，用手势触发重新请求页面数据。
      child: RefreshIndicator(
        onRefresh: _refreshHomeContent,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          // 这里改用 `CustomScrollView`，因为它能把多个不同类型的滚动区块组合起来。
          // 当页面需要“推荐区标题吸顶”这类能力时，`Sliver` 体系会比普通 `ListView` 更合适。
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _HomeSearchBar(),
                    const SizedBox(height: 16),
                    HomeBannerCarousel(
                      key: ValueKey<int>(_bannerRefreshVersion),
                    ),
                    const SizedBox(height: 24),
                    _HomeSectionTitle(
                      title: '热门分类',
                      subtitle: '先用快捷入口模拟电商首页里的一级分类导航',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: HomePage._categories
                          .map(
                            (item) => _HomeCategoryChip(
                              item: item,
                              onTap: () =>
                                  widget.onCategoryTap?.call(item.label),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _RecommendSectionHeaderDelegate(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              sliver: _buildRecommendContentSliver(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendContentSliver() {
    if (_isInitialLoading) {
      return const SliverToBoxAdapter(child: _RecommendLoadingPlaceholder());
    }

    return SliverList.list(
      children: [
        ..._products.map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RecommendProductCard(
              name: product.name,
              description: product.description,
              priceLabel: product.priceLabel,
              tag: product.tag,
              onTap: () => _openProductDetail(product),
            ),
          ),
        ),
        if (_isLoadingMore) const _RecommendLoadMoreIndicator(),
        if (!_hasMore) const _RecommendLoadMoreFinished(),
      ],
    );
  }
}

/// 搜索栏占位组件。
///
/// 这里暂时不接真实输入框，而是先做成一个可视化搜索入口，
/// 方便后续再学习表单输入和搜索交互。
class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.search),
          const SizedBox(width: 12),
          Text('搜一搜你感兴趣的商品', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// 区块标题组件。
///
/// 首页通常由多个 section 组成，把标题样式提出来后，
/// 后续新增区块时可以复用同一套视觉结构。
class _HomeSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HomeSectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// 推荐区吸顶标题。
///
/// `SliverPersistentHeader` 可以理解成“会参与滚动、但满足条件后能固定住的头部区块”。
/// 电商里常见的吸顶筛选条、分类条、分组标题，很多都可以用这个思路实现。
class _RecommendSectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _RecommendSectionHeaderDelegate({required this.backgroundColor});

  final Color backgroundColor;

  static const double _headerHeight = 84;

  @override
  double get minExtent => _headerHeight;

  @override
  double get maxExtent => _headerHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: _HomeSectionTitle(
            title: '为你推荐',
            subtitle: '当前先用 mock 请求模拟分页加载，后续可替换成真实商品接口',
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_RecommendSectionHeaderDelegate oldDelegate) {
    return backgroundColor != oldDelegate.backgroundColor;
  }
}

/// 推荐区的首次加载占位。
///
/// 首次进页面时，用户还没有看到任何商品，
/// 所以这里单独给一个更明确的“加载中”反馈。
class _RecommendLoadingPlaceholder extends StatelessWidget {
  const _RecommendLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 12),
            Text('推荐商品加载中...'),
          ],
        ),
      ),
    );
  }
}

/// 推荐区的“正在加载下一页”提示。
///
/// 它和首次加载提示分开，是为了让用户知道：
/// 当前不是整页空白等待，而是已经有内容的基础上继续追加数据。
class _RecommendLoadMoreIndicator extends StatelessWidget {
  const _RecommendLoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 4, bottom: 20),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 8),
            Text('正在加载更多推荐商品...'),
          ],
        ),
      ),
    );
  }
}

/// 推荐区的加载完成提示。
///
/// 分页加载常见的一个交互细节，是在没有更多数据时给出明确反馈，
/// 避免用户误以为页面卡住了。
class _RecommendLoadMoreFinished extends StatelessWidget {
  const _RecommendLoadMoreFinished();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      child: Center(
        child: Text(
          '推荐商品已经全部加载完成',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

/// 分类快捷入口。
///
/// 这里用 `Wrap` 包裹多个卡片，可以在空间不够时自动换行。
/// 这很适合做数量不多、需要平铺展示的入口按钮。
class _HomeCategoryChip extends StatelessWidget {
  final _HomeCategoryItem item;
  final VoidCallback onTap;

  const _HomeCategoryChip({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon),
              const SizedBox(height: 8),
              Text(item.label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// 分类入口的数据结构。
///
/// 这里先用一个很轻量的类来描述首页分类项，
/// 比直接在页面里写多组散落的字符串更容易维护。
class _HomeCategoryItem {
  final String label;
  final IconData icon;

  const _HomeCategoryItem({required this.label, required this.icon});
}
