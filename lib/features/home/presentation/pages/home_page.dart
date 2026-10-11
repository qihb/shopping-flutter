import 'package:flutter/material.dart';

import 'package:my_first_app/app/config/app_config_store.dart';
import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:my_first_app/features/product/data/models/category_node.dart';
import 'package:my_first_app/features/product/data/models/page_result.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';
import 'package:my_first_app/features/product/data/product_service.dart';
import 'package:my_first_app/features/product/presentation/pages/product_detail_page.dart';
import 'package:my_first_app/features/product/presentation/widgets/product_card.dart';

/// 首页页面。
///
/// 推荐商品与热门分类数据均来自 spring-shop 后端接口：
/// - 推荐流通过 [ProductService.fetchProducts] 按页加载
/// - 热门分类入口通过 [ProductService.fetchCategoryTree] 取一级分类
class HomePage extends StatefulWidget {
  /// 一级分类名到图标的映射，未命中的分类统一用兜底图标。
  static const Map<String, IconData> _categoryIconMap = <String, IconData>{
    '服饰': Icons.checkroom_outlined,
    '鞋靴': Icons.hiking_outlined,
    '箱包': Icons.work_outline,
    '数码': Icons.devices_outlined,
    '家居': Icons.chair_outlined,
    '食品': Icons.local_grocery_store_outlined,
  };

  final void Function(CategoryNode category)? onCategoryTap;
  final ValueChanged<ProductSummary>? onAddToCart;

  /// 可选注入的商品服务，主要用于测试。
  final ProductService? productService;

  const HomePage({
    super.key,
    this.onCategoryTap,
    this.onAddToCart,
    this.productService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  /// 使用 spring-shop 后端的商品服务。
  ///
  /// 优先使用外部注入的服务（测试时可注入 mock），
  /// 否则按当前环境配置的 baseUrl 懒创建真实实例。
  late final ProductService _productService = widget.productService ??
      ProductService(
        apiClient: ApiClient(baseUrl: AppConfigStore.instance.apiBaseUrl),
      );

  final List<ProductSummary> _products = [];
  List<CategoryNode> _categories = <CategoryNode>[];

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
    _loadCategories();
    _loadMoreProducts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载一级分类快捷入口。
  ///
  /// 属于锦上添花的导航区，加载失败时静默回退为空列表，
  /// 不影响下方推荐流的正常浏览。
  Future<void> _loadCategories() async {
    try {
      final List<CategoryNode> categories =
          await _productService.fetchCategoryTree();

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      // 静默失败：分类入口缺席，推荐流仍然可用。
    }
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
      final PageResult<ProductSummary> pageResult = await _productService
          .fetchProducts(current: _nextPage);

      if (!mounted) {
        _isRequestInFlight = false;
        return;
      }

      setState(() {
        _products.addAll(pageResult.records);
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
    _loadCategories();
  }

  void _openProductDetail(ProductSummary product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          productId: product.id,
          productService: _productService,
          onAddToCart: widget.onAddToCart,
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
                      subtitle: '来自后端分类树的一级分类，点击直达分类页',
                    ),
                    const SizedBox(height: 12),
                    if (_categories.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _categories
                            .map(
                              (category) => _HomeCategoryChip(
                                category: category,
                                onTap: () =>
                                    widget.onCategoryTap?.call(category),
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
            child: ProductCard(
              product: product,
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
            subtitle: '数据来自 spring-shop 后端商品接口',
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
  final CategoryNode category;
  final VoidCallback onTap;

  const _HomeCategoryChip({required this.category, required this.onTap});

  IconData get _icon =>
      HomePage._categoryIconMap[category.name] ?? Icons.category_outlined;

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
              Icon(_icon),
              const SizedBox(height: 8),
              Text(category.name, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
