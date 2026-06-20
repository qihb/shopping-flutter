import 'package:flutter/material.dart';

import 'package:my_first_app/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:my_first_app/features/home/presentation/widgets/recommend_product_card.dart';

/// 首页占位页面。
///
/// 这个页面现在不再自己包 `Scaffold`，
/// 因为外层已经有一个统一承载底部导航的主页面。
///
/// 当前首页先做成一个“电商首页草图”：
/// - 顶部搜索入口
/// - 活动横幅
/// - 分类快捷入口
/// - 推荐商品列表
///
/// 这样做的目的不是一次把业务做完，
/// 而是先把最常见的首页区块和布局方式串起来，方便后续继续迭代。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<_HomeCategoryItem> _categories = [
    _HomeCategoryItem(label: '服饰', icon: Icons.checkroom_outlined),
    _HomeCategoryItem(label: '鞋靴', icon: Icons.hiking_outlined),
    _HomeCategoryItem(label: '箱包', icon: Icons.work_outline),
    _HomeCategoryItem(label: '数码', icon: Icons.devices_outlined),
    _HomeCategoryItem(label: '家居', icon: Icons.chair_outlined),
    _HomeCategoryItem(label: '食品', icon: Icons.local_grocery_store_outlined),
  ];

  static const List<_RecommendProduct> _products = [
    _RecommendProduct(
      name: '夏季轻运动鞋',
      description: '透气网面设计，适合通勤和日常轻运动。',
      priceLabel: 'EUR 89',
      tag: '上新',
    ),
    _RecommendProduct(
      name: '极简双肩包',
      description: '通勤与短途出行都适合的轻量收纳包。',
      priceLabel: 'EUR 129',
      tag: '人气',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // `ListView` 是 Flutter 里最常见的滚动列表组件之一。
      // 首页内容通常会超过一屏，所以这里先用它把多个业务区块串成一个可滚动页面。
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HomeSearchBar(),
          const SizedBox(height: 16),
          const HomeBannerCarousel(),
          const SizedBox(height: 24),
          _HomeSectionTitle(
            title: '热门分类',
            subtitle: '先用快捷入口模拟电商首页里的一级分类导航',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _categories
                .map((item) => _HomeCategoryChip(item: item))
                .toList(),
          ),
          const SizedBox(height: 24),
          const _HomeSectionTitle(
            title: '为你推荐',
            subtitle: '推荐区先用静态假数据，后续再逐步接真实商品列表',
          ),
          const SizedBox(height: 12),
          ..._products.map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecommendProductCard(
                name: product.name,
                description: product.description,
                priceLabel: product.priceLabel,
                tag: product.tag,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 搜索栏占位组件。
///
/// 这里暂时不接真实输入框，而是先做成一个可视化搜索入口，
/// 方便后续再学习表单输入和搜索交互。
class _HomeSearchBar extends StatelessWidget {
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
          Text(
            '搜一搜你感兴趣的商品',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
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
  const _HomeSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

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

/// 分类快捷入口。
///
/// 这里用 `Wrap` 包裹多个卡片，可以在空间不够时自动换行。
/// 这很适合做数量不多、需要平铺展示的入口按钮。
class _HomeCategoryChip extends StatelessWidget {
  const _HomeCategoryChip({required this.item});

  final _HomeCategoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
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
    );
  }
}

/// 分类入口的数据结构。
///
/// 这里先用一个很轻量的类来描述首页分类项，
/// 比直接在页面里写多组散落的字符串更容易维护。
class _HomeCategoryItem {
  const _HomeCategoryItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// 推荐商品的数据结构。
///
/// 当前先把它放在页面文件里，保持学习阶段实现足够直接。
/// 如果后面商品结构变复杂，再继续拆到独立文件也更自然。
class _RecommendProduct {
  const _RecommendProduct({
    required this.name,
    required this.description,
    required this.priceLabel,
    required this.tag,
  });

  final String name;
  final String description;
  final String priceLabel;
  final String tag;
}
