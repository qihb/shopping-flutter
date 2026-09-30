import 'package:flutter/material.dart';

import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';

/// 商品详情页。
///
/// 页面包含顶部商品展示区、标签/标题/价格/简介信息区与底部操作按钮，
/// 承接首页推荐商品的“点击进入详情”链路。
class ProductDetailPage extends StatelessWidget {
  final HomeRecommendProduct product;
  final VoidCallback? onAddToCart;

  const ProductDetailPage({super.key, required this.product, this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('商品详情')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
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
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProductTagChip(label: product.tag),
              const _ProductTagChip(label: '精选'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            product.name,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.priceLabel,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.description,
            style: textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          Text(
            '商品说明',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '该区域展示商品的核心卖点与规格说明，具体参数与售后以实际商品为准。',
            style: textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey<String>('product-detail-add-to-cart'),
                  onPressed: () {
                    onAddToCart?.call();
                    Navigator.of(context).pop();
                  },
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
          ),
        ],
      ),
    );
  }
}

class _ProductTagChip extends StatelessWidget {
  final String label;

  const _ProductTagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
