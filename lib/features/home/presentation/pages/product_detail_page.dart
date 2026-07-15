import 'package:flutter/material.dart';

import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';

/// 商品详情页。
///
/// 这里先做一个适合当前学习阶段的详情页初版：
/// - 顶部商品展示区
/// - 商品标签、标题、价格和简介
/// - 底部操作按钮
///
/// 这样一来，首页的推荐商品就不只是“能看到”，
/// 而是已经具备了“点进去继续浏览”的基本链路。
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    super.key,
    required this.product,
  });

  final HomeRecommendProduct product;

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
              const _ProductTagChip(label: '详情初版'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            product.name,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
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
            '这一版先用静态文案模拟商品详情页的核心信息区，后面可以继续补轮播图、规格选择、评价和详情图文。',
            style: textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('加入购物车'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
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
  const _ProductTagChip({required this.label});

  final String label;

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
