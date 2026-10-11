import 'package:flutter/material.dart';

import 'package:my_first_app/app/config/app_config_store.dart';
import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/features/product/data/models/category_node.dart';
import 'package:my_first_app/features/product/data/models/page_result.dart';
import 'package:my_first_app/features/product/data/models/product_sku.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';
import 'package:my_first_app/features/product/data/product_service.dart';
import 'package:my_first_app/features/product/presentation/pages/product_detail_page.dart';
import 'package:my_first_app/features/product/presentation/widgets/product_card.dart';

/// 分类页。
///
/// 采用“左侧分类导航 + 右侧商品列表”的双栏结构，
/// 这是电商 App 常见的分类页组织方式。
///
/// 左侧展示后端分类树的一级分类；选中分类若有子分类，
/// 右侧顶部横滑 chips 展示二级分类，商品列表按当前选中分类 id 分页加载。
class CategoryPage extends StatefulWidget {
  /// 承接“从首页点击某个分类后，分类页默认选中哪个一级分类”，
  /// 等价于进入页面时携带的初始筛选条件。
  final int? initialCategoryId;

  /// 加购回调透传到商品详情页，携带详情页当前选中的 SKU；
  /// 返回值语义见 [ProductDetailPage.onAddToCart]。
  final bool Function(ProductSummary product, ProductSku? sku)? onAddToCart;

  /// 可选注入的商品服务，主要用于测试；为 null 时懒创建真实实例。
  final ProductService? productService;

  const CategoryPage({
    super.key,
    this.initialCategoryId,
    this.onAddToCart,
    this.productService,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final ScrollController _scrollController = ScrollController();

  /// 与 HomePage 一致：service 为 null 时按当前环境配置懒创建真实实例。
  late final ProductService _productService = widget.productService ??
      ProductService(
        apiClient: ApiClient(baseUrl: AppConfigStore.instance.apiBaseUrl),
      );

  List<CategoryNode> _categories = <CategoryNode>[];
  bool _isCategoriesLoading = true;
  String? _categoryErrorMessage;

  int _selectedCategoryIndex = 0;

  /// 有子分类时右侧默认选中的二级分类下标。
  int _selectedSubIndex = 0;

  final List<ProductSummary> _products = <ProductSummary>[];
  bool _isProductsLoading = false;
  bool _isLoadingMore = false;
  bool _isRequestInFlight = false;
  bool _hasMore = true;
  int _nextPage = 1;
  String? _productErrorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadCategories();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 首页分类入口切换目标分类时，重新定位左侧选中项并刷新商品。
    if (oldWidget.initialCategoryId != widget.initialCategoryId &&
        _categories.isNotEmpty) {
      _selectCategory(_findInitialCategoryIndex());
    }
  }

  int _findInitialCategoryIndex() {
    final int? targetId = widget.initialCategoryId;

    if (targetId == null) {
      return 0;
    }

    final int index =
        _categories.indexWhere((category) => category.id == targetId);

    return index >= 0 ? index : 0;
  }

  CategoryNode? get _activeCategory {
    if (_categories.isEmpty) {
      return null;
    }
    return _categories[_selectedCategoryIndex.clamp(0, _categories.length - 1)];
  }

  CategoryNode? get _activeSubCategory {
    final CategoryNode? category = _activeCategory;
    if (category == null || category.children.isEmpty) {
      return null;
    }
    return category.children[_selectedSubIndex.clamp(
      0,
      category.children.length - 1,
    )];
  }

  /// 当前用于查询商品的分类 id：有子分类用子分类，否则用一级分类。
  int? get _activeCategoryId =>
      _activeSubCategory?.id ?? _activeCategory?.id;

  /// 当前右侧标题：子分类名优先，其次一级分类名。
  String get _activeCategoryLabel =>
      _activeSubCategory?.name ?? _activeCategory?.name ?? '';

  /// 加载分类树；失败时给出错误态与重试入口。
  Future<void> _loadCategories() async {
    setState(() {
      _isCategoriesLoading = true;
      _categoryErrorMessage = null;
    });

    try {
      final List<CategoryNode> categories =
          await _productService.fetchCategoryTree();

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _isCategoriesLoading = false;
        _selectedCategoryIndex = _findInitialCategoryIndex();
        _selectedSubIndex = 0;
      });
      _reloadProducts();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCategoriesLoading = false;
        _categoryErrorMessage = '分类加载失败，请重试。';
      });
    }
  }

  /// 切换左侧一级分类：重置二级选中并重新加载商品。
  void _selectCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _selectedSubIndex = 0;
    });
    _reloadProducts();
  }

  /// 切换右侧二级分类 chips。
  void _selectSubCategory(int index) {
    setState(() {
      _selectedSubIndex = index;
    });
    _reloadProducts();
  }

  /// 清空商品列表回到第一页并重新加载。
  Future<void> _reloadProducts() async {
    if (_isRequestInFlight) {
      return;
    }

    setState(() {
      _products.clear();
      _isProductsLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _nextPage = 1;
      _productErrorMessage = null;
    });

    await _loadMoreProducts();
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
    final int? categoryId = _activeCategoryId;

    if (_isRequestInFlight || !_hasMore || categoryId == null) {
      return;
    }

    _isRequestInFlight = true;

    if (_nextPage > 1) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final PageResult<ProductSummary> pageResult = await _productService
          .fetchProducts(categoryId: categoryId, current: _nextPage);

      if (!mounted) {
        _isRequestInFlight = false;
        return;
      }

      setState(() {
        _products.addAll(pageResult.records);
        _hasMore = pageResult.hasMore;
        _nextPage += 1;
        _isProductsLoading = false;
        _isLoadingMore = false;
        _isRequestInFlight = false;
        _productErrorMessage = null;
      });
    } catch (e) {
      if (!mounted) {
        _isRequestInFlight = false;
        return;
      }

      setState(() {
        _isProductsLoading = false;
        _isLoadingMore = false;
        _isRequestInFlight = false;
        _productErrorMessage = '分类商品加载失败，请重试。';
      });
    }
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Row(
        children: [
          _buildLeftNav(colorScheme),
          Expanded(
            // `Expanded` 占满 `Row` 剩余空间，让右侧内容区铺满。
            child: Container(
              color: colorScheme.surface,
              child: _buildRightPanel(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 左侧一级分类导航，含加载与错误态。
  Widget _buildLeftNav(ColorScheme colorScheme) {
    if (_isCategoriesLoading) {
      return SizedBox(
        width: 96,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_categoryErrorMessage != null) {
      return SizedBox(
        width: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 32),
            const SizedBox(height: 8),
            Text(
              _categoryErrorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadCategories,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 96,
      color: colorScheme.surfaceContainerLowest,
      child: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final CategoryNode category = _categories[index];
          final bool isSelected = index == _selectedCategoryIndex;

          return InkWell(
            onTap: () => _selectCategory(index),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.surface
                    : colorScheme.surfaceContainerLowest,
                border: Border(
                  left: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                category.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 右侧面板：二级分类 chips + 商品分页列表。
  Widget _buildRightPanel(BuildContext context) {
    if (_categoryErrorMessage != null) {
      return _CategoryErrorPlaceholder(
        message: _categoryErrorMessage!,
        onRetry: _loadCategories,
      );
    }

    if (_isCategoriesLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (_activeCategory == null) {
      return const Center(child: Text('暂无分类'));
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: _CategorySectionHeader(label: _activeCategoryLabel),
        ),
        if (_activeCategory!.hasChildren)
          SliverToBoxAdapter(
            child: _SubCategoryChips(
              children: _activeCategory!.children,
              selectedIndex: _selectedSubIndex,
              onTap: _selectSubCategory,
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          sliver: _buildProductContentSliver(),
        ),
      ],
    );
  }

  Widget _buildProductContentSliver() {
    if (_isProductsLoading && _products.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }

    if (_productErrorMessage != null && _products.isEmpty) {
      return SliverToBoxAdapter(
        child: _CategoryErrorPlaceholder(
          message: _productErrorMessage!,
          onRetry: _reloadProducts,
        ),
      );
    }

    if (_products.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('该分类下暂时没有商品')),
        ),
      );
    }

    return SliverList.list(
      children: [
        ..._products.map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ProductCard(
              product: product,
              onTap: () => _openProductDetail(product),
            ),
          ),
        ),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ),
        if (!_hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Center(
              child: Text(
                '已经到底啦',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }
}

/// 右侧顶部标题：展示当前选中的分类名。
class _CategorySectionHeader extends StatelessWidget {
  final String label;

  const _CategorySectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// 二级分类横滑 chips。
class _SubCategoryChips extends StatelessWidget {
  final List<CategoryNode> children;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _SubCategoryChips({
    required this.children,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 56,
      // `SingleChildScrollView` + `Row` 实现横向滑动的一排 chips。
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: children.length,
        separatorBuilder: (_, int index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final CategoryNode child = children[index];
          final bool isSelected = index == selectedIndex;

          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onTap(index),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  child.name,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 分类页错误占位：错误文案 + 重试按钮。
class _CategoryErrorPlaceholder extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CategoryErrorPlaceholder({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
