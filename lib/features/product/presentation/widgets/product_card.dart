import 'package:flutter/material.dart';

import 'package:my_first_app/features/product/data/models/product_summary.dart';

/// 通用商品卡片。
///
/// 首页推荐流与分类页商品列表共用：网络主图 + 名称 + 副标题 + 价格 + 销量。
/// 主图为空或加载失败时回退到占位图标，保证弱网/测试环境下不报错。
class ProductCard extends StatelessWidget {
  final ProductSummary product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // 测试与 E2E 通过 `home-product-card-<商品名>` 形态的 key 定位卡片。
        key: ValueKey<String>('home-product-card-${product.name}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainImage(colorScheme),
              const SizedBox(width: 16),
              Expanded(
                // `Expanded` 会占满 `Row` 中剩余的可用空间，
                // 让右侧文案区域自动拉伸。
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (product.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        product.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '¥${_formatPrice(product.minPrice)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '已售 ${product.sales}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.chevron_right, color: colorScheme.outline),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 左侧主图区域：空地址直接展示占位图标，
  /// 网络图加载失败时通过 errorBuilder 回退到同一个占位。
  Widget _buildMainImage(ColorScheme colorScheme) {
    if (product.mainImage.isEmpty) {
      return _buildImagePlaceholder(colorScheme);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 76,
        height: 76,
        child: Image.network(
          product.mainImage,
          fit: BoxFit.cover,
          errorBuilder: (_, Object error, StackTrace? stackTrace) =>
              _buildImagePlaceholder(colorScheme),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, size: 32, color: colorScheme.primary),
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
