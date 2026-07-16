import 'package:flutter/material.dart';

/// 首页推荐商品卡片。
///
/// `Card` 可以理解成 Material 风格里很常见的一种“信息承载容器”。
/// 电商首页里的商品推荐、订单摘要、地址信息等内容，经常都可以放进卡片里展示。
class RecommendProductCard extends StatelessWidget {
  final String name;
  final String description;
  final String priceLabel;
  final String tag;
  final VoidCallback? onTap;

  const RecommendProductCard({
    super.key,
    required this.name,
    required this.description,
    required this.priceLabel,
    required this.tag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.image_outlined, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                // `Expanded` 会占满 `Row` 中剩余空间，
                // 很适合让右侧的商品文案区域自动拉伸。
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      priceLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
