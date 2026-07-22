import 'package:flutter/material.dart';

import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/features/home/data/home_recommend_service.dart';
import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';
import 'package:my_first_app/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:my_first_app/features/home/presentation/widgets/recommend_product_card.dart';
import 'package:my_first_app/features/home/presentation/pages/product_detail_page.dart';

/// 首页页面。
///
/// 现在推荐商品数据从 [HomeRecommendService] 获取，
/// 它内部通过 `http` 包发起真实 HTTP GET 请求到 FakeStore API，
/// 替换了之前的 mock 延迟。
class HomePage extends StatefulWidget {
  static const List<_HomeCategoryItem> _categories = [
    _HomeCategoryItem(label: '服饰', icon: Icons.checkroom_outlined),
    _HomeCategoryItem(label: '鞋靴', icon: Icons.hiking_outlined),
    _HomeCategoryItem(label: '箱包', icon: Icons.work_outline),
    _HomeCategoryItem(label: '数码', icon: Icons.devices_outlined),
    _HomeCategoryItem(label: '家居', icon: Icons.chair_outlined),
    _HomeCategoryItem(label: '食品', icon: Icons.local_grocery_store_outlined),
  ];

  final ValueChanged<String>? onCategoryTap;
  final ValueChanged<HomeRecommendProduct>? onAddToCart;

  /// 可选注入的推荐服务，主要用于测试。
  final HomeRecommendService? recommendService;

  const HomePage({
    super.key,
    this.onCategoryTap,
    this.onAddToCart,
    this.recommendService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  /// 使用真实 HTTP 请求的推荐服务。
  ///
  /// 优先使用外部注入的服务（测试时可注入 mock），
  /// 否则默认连接到 FakeStore API。
  late final HomeRecommendService _recommendService = widget.recommendService ??
      HomeRecommendService(
        apiClient: ApiClient(baseUrl: 'https://fakestoreapi.com'),
      );

  final List<HomeRecommendProduct> _products = <HomeRecommendProduct>[];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _isRequestInFlight = false;
  bool _hasMore = true;
  int _nextPage = 1;
  int _bannerRefreshVersion = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
        _errorMessage = null;
      });
    }

    try {
      final HomeRecommendPageResult pageResult =
          await _recommendService.fetchRecommendProducts(page: _nextPage);

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
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) {
        _isRequestInFlight = false;
        return;
      }

      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
        _isRequestInFlight = false;
        _errorMessage = '推荐商品加载失败，请下拉刷新重试。\n($e)';
      });
    }
  }

  Future<void> _refreshHomeContent() async {
    if (_isRequestInFlight) {
      return;
    }

    setState(() {
      _products.clear();
      _isInitialLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _nextPage = 1;
      _bannerRefreshVersion += 1;
      _errorMessage = null;
    });

    await _loadMoreProducts();
  }

  void _openProductDetail(HomeRecommendProduct product) {
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
      child: RefreshIndicator(
        onRefresh: _refreshHomeContent,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
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

    if (_errorMessage != null && _products.isEmpty) {
      return SliverToBoxAdapter(
        child: _RecommendErrorPlaceholder(
          message: _errorMessage!,
          onRetry: _refreshHomeContent,
        ),
      );
    }

    return SliverList.list(
      children: [
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RecommendErrorBanner(message: _errorMessage!),
          ),
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
            subtitle: '数据来自 FakeStore API，通过 http 包发起真实网络请求',
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

/// 推荐区错误状态占位。
class _RecommendErrorPlaceholder extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RecommendErrorPlaceholder({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.wifi_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 推荐区错误横幅。
class _RecommendErrorBanner extends StatelessWidget {
  final String message;

  const _RecommendErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 推荐区的"正在加载下一页"提示。
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
class _HomeCategoryItem {
  final String label;
  final IconData icon;

  const _HomeCategoryItem({required this.label, required this.icon});
}
