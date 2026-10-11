import 'package:flutter/material.dart';

import 'package:my_first_app/app/config/app_config_store.dart';
import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/product/data/models/product_detail.dart';
import 'package:my_first_app/features/product/data/models/product_sku.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';
import 'package:my_first_app/features/product/data/product_service.dart';

/// 商品详情页。
///
/// 按 [ProductDetailPage.productId] 从后端加载商品详情，
/// 包含图片轮播、标题/价格区、SKU 选择与商品说明区块，
/// 承接首页与分类页的“点击商品进入详情”链路。
class ProductDetailPage extends StatefulWidget {
  final int productId;

  /// 可选注入的商品服务，主要用于测试；为 null 时懒创建真实实例。
  final ProductService? productService;

  /// 加购回调：携带当前选中的 SKU。
  ///
  /// 服务端加购请求（`CartAddRequest`）按 SKU 维度提交，
  /// 没有选中 SKU（如商品未配置规格）时 `sku` 为 null，由上层编排提示。
  ///
  /// 返回 `true` 表示上层已经完成了页面导航（例如未登录时跳转登录页），
  /// 此时详情页应保留在栈里，登录后返回可再次加购；
  /// 返回 `false` 表示没有发生导航，详情页自行退出。
  final bool Function(ProductSummary product, ProductSku? sku)? onAddToCart;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.productService,
    this.onAddToCart,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  /// 与 HomePage 一致：service 为 null 时按当前环境配置懒创建真实实例。
  late final ProductService _productService = widget.productService ??
      ProductService(
        apiClient: ApiClient(baseUrl: AppConfigStore.instance.apiBaseUrl),
      );

  bool _isLoading = true;
  String? _errorMessage;
  ProductDetail? _detail;

  /// 当前选中的 SKU 下标，详情加载完成后默认选第一个。
  int _selectedSkuIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ProductDetail detail =
          await _productService.fetchProductDetail(widget.productId);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _detail = detail;
        _selectedSkuIndex = 0;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            e is ApiException ? e.message : '商品详情加载失败，请稍后重试';
      });
    }
  }

  ProductSku? get _selectedSku {
    final ProductDetail? detail = _detail;
    if (detail == null || detail.skus.isEmpty) {
      return null;
    }
    return detail.skus[_selectedSkuIndex.clamp(0, detail.skus.length - 1)];
  }

  /// 用详情数据反推一个列表摘要，作为加购回调的参数，
  /// 让购物车链路继续复用 [ProductSummary] 这一个模型。
  ProductSummary get _summaryFromDetail {
    final ProductDetail detail = _detail!;
    return ProductSummary(
      id: detail.id,
      categoryId: detail.categoryId,
      categoryName: detail.categoryName,
      name: detail.name,
      subtitle: detail.subtitle,
      mainImage: detail.mainImage,
      minPrice: detail.minPrice,
      sales: detail.sales,
      status: detail.status,
      createTime: '',
    );
  }

  void _handleAddToCart() {
    // 上层跳了登录页时返回 true，此时详情页不能 pop，
    // 否则会把刚压栈的登录页顶出栈，登录引导就失效了。
    final bool didNavigate =
        widget.onAddToCart?.call(_summaryFromDetail, _selectedSku) ?? false;

    if (!didNavigate) {
      Navigator.of(context).pop();
    }
  }

  /// 轮播图片地址：优先用商品图集，没有图集时回退主图。
  List<String> get _imageUrls {
    final ProductDetail detail = _detail!;
    if (detail.images.isNotEmpty) {
      return detail.images.map((image) => image.imageUrl).toList();
    }
    return detail.mainImage.isEmpty
        ? <String>[]
        : <String>[detail.mainImage];
  }

  /// 后端 detail 字段是富文本 HTML，当前先用纯文本降级展示：
  /// 剥掉标签后合并空白；富文本渲染（flutter_html 之类）是后续计划。
  String get _plainDetailText {
    final String raw = _detail!.detail;
    final String withoutTags = raw.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商品详情')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 12),
            Text('商品详情加载中...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 48),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildImageCarousel(context),
        const SizedBox(height: 20),
        _buildTitleArea(context),
        const SizedBox(height: 16),
        _buildPriceArea(context),
        if (_detail!.skus.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSkuSelector(context),
        ],
        if (_plainDetailText.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            '商品说明',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _plainDetailText,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
        const SizedBox(height: 24),
        _buildActionBar(context),
      ],
    );
  }

  /// 顶部图片轮播：无图集时回退主图，连主图都没有时展示占位。
  Widget _buildImageCarousel(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final List<String> imageUrls = _imageUrls;

    if (imageUrls.isEmpty) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 72,
          color: colorScheme.primary,
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final String url = imageUrls[index];

          if (url.isEmpty) {
            return _buildNetworkImagePlaceholder(colorScheme);
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            // 测试环境加载不了真实网络图，errorBuilder 回退占位避免报错。
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, Object error, StackTrace? stackTrace) =>
                  _buildNetworkImagePlaceholder(colorScheme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkImagePlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.secondaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 56,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildTitleArea(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _detail!.name,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (_detail!.subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _detail!.subtitle,
            style: textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '已售 ${_detail!.sales} · ${_detail!.categoryName}',
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 价格区：展示商品最低价，并带上选中 SKU 的划线价。
  Widget _buildPriceArea(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ProductSku? sku = _selectedSku;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '¥${_formatPrice(_detail!.minPrice)}',
          style: textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        // 划线价只在确实高于现价时展示，避免出现“原价更低”的怪异对比。
        if (sku != null && sku.originalPrice > _detail!.minPrice) ...[
          const SizedBox(width: 8),
          Text(
            '¥${_formatPrice(sku.originalPrice)}',
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }

  /// SKU 横向选择 chips：展示规格描述与库存，选中态高亮。
  Widget _buildSkuSelector(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _detail!.skus.length,
        separatorBuilder: (_, int index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final ProductSku sku = _detail!.skus[index];
          final bool isSelected = index == _selectedSkuIndex;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() {
              _selectedSkuIndex = index;
            }),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sku.specs.isEmpty ? '默认规格' : sku.specs,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '库存 ${sku.stock}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const ValueKey<String>('product-detail-add-to-cart'),
            onPressed: _handleAddToCart,
            child: const Text('加入购物车'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            key: const ValueKey<String>('product-detail-buy-now'),
            onPressed: () {},
            child: const Text('立即购买'),
          ),
        ),
      ],
    );
  }

  /// 金额展示：整数省略小数位，非整数保留原值。
  static String _formatPrice(double price) {
    if (price == price.truncateToDouble()) {
      return '${price.toInt()}';
    }
    return '$price';
  }
}
