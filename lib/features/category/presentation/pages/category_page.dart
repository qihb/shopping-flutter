import 'package:flutter/material.dart';

import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';
import 'package:my_first_app/features/home/presentation/pages/product_detail_page.dart';

/// 分类页。
///
/// 这里把页面改成了“左侧分类导航 + 右侧商品网格”的双栏结构，
/// 这是电商 App 里很常见的一种分类页组织方式。
///
/// 左边更像“当前浏览的大类目录”，右边则展示当前分类下的商品卡片列表。
/// 先把这个基础骨架搭起来，后面再继续接筛选、二级分类和真实数据。
class CategoryPage extends StatefulWidget {
  /// 这个参数用来承接“从首页点某个分类后，分类页应该默认选中谁”。
  ///
  /// 你可以先把它理解成网页里进入页面时携带的初始筛选条件。
  final String? initialCategoryLabel;
  final ValueChanged<HomeRecommendProduct>? onAddToCart;

  const CategoryPage({super.key, this.initialCategoryLabel, this.onAddToCart});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late int _selectedCategoryIndex;

  @override
  void initState() {
    super.initState();
    _selectedCategoryIndex = _findInitialCategoryIndex();
  }

  @override
  void didUpdateWidget(covariant CategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialCategoryLabel != widget.initialCategoryLabel) {
      _selectedCategoryIndex = _findInitialCategoryIndex();
    }
  }

  int _findInitialCategoryIndex() {
    final String? targetLabel = widget.initialCategoryLabel;

    if (targetLabel == null) {
      return 0;
    }

    final int index = _categorySections.indexWhere(
      (section) => section.label == targetLabel,
    );

    return index >= 0 ? index : 0;
  }

  void _openProductDetail({
    required _CategorySection section,
    required _CategoryProduct product,
  }) {
    final HomeRecommendProduct detailProduct = HomeRecommendProduct(
      name: product.name,
      description: '${section.label}分类里的精选单品，后面可以继续补更完整的商品卖点说明。',
      priceLabel: 'EUR ${product.priceLabel}',
      tag: section.label,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          product: detailProduct,
          onAddToCart: () => widget.onAddToCart?.call(detailProduct),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _CategorySection activeSection =
        _categorySections[_selectedCategoryIndex];
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Row(
        children: [
          Container(
            width: 96,
            color: colorScheme.surfaceContainerLowest,
            child: ListView.builder(
              itemCount: _categorySections.length,
              itemBuilder: (context, index) {
                final _CategorySection section = _categorySections[index];
                final bool isSelected = index == _selectedCategoryIndex;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
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
                      section.label,
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
          ),
          Expanded(
            // `Expanded` 会让右侧内容区占满 `Row` 剩余空间。
            // 在双栏布局里，这是一种很常见的写法。
            child: Container(
              color: colorScheme.surface,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    sliver: SliverToBoxAdapter(
                      child: _CategorySectionHeader(section: activeSection),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final _CategoryProduct product =
                            activeSection.products[index];

                        return _CategoryProductCard(
                          product: product,
                          onTap: () => _openProductDetail(
                            section: activeSection,
                            product: product,
                          ),
                        );
                      }, childCount: activeSection.products.length),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.55,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySectionHeader extends StatelessWidget {
  final _CategorySection section;

  const _CategorySectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.label,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          section.description,
          style: textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

class _CategoryProductCard extends StatelessWidget {
  final _CategoryProduct product;
  final VoidCallback onTap;

  const _CategoryProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      key: ValueKey<String>('category-product-${product.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(product.icon, color: colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'EUR ${product.priceLabel}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection {
  final String label;
  final String description;
  final List<_CategoryProduct> products;

  const _CategorySection({
    required this.label,
    required this.description,
    required this.products,
  });
}

class _CategoryProduct {
  final String name;
  final String priceLabel;
  final IconData icon;

  const _CategoryProduct({
    required this.name,
    required this.priceLabel,
    required this.icon,
  });
}

const List<_CategorySection> _categorySections = [
  _CategorySection(
    label: '服饰',
    description: '先用 1 行 4 个的商品网格，模拟电商分类页里常见的商品入口排布。',
    products: [
      _CategoryProduct(
        name: '运动速干T恤',
        priceLabel: '129',
        icon: Icons.checkroom_outlined,
      ),
      _CategoryProduct(
        name: '轻量防晒衬衫',
        priceLabel: '169',
        icon: Icons.sunny_snowing,
      ),
      _CategoryProduct(
        name: '高腰运动短裤',
        priceLabel: '149',
        icon: Icons.directions_run_outlined,
      ),
      _CategoryProduct(
        name: '针织背心',
        priceLabel: '99',
        icon: Icons.style_outlined,
      ),
      _CategoryProduct(
        name: '基础款牛仔裤',
        priceLabel: '199',
        icon: Icons.shopping_bag_outlined,
      ),
      _CategoryProduct(
        name: '夏日牛仔外套',
        priceLabel: '239',
        icon: Icons.iron_outlined,
      ),
      _CategoryProduct(
        name: '棉质半身裙',
        priceLabel: '159',
        icon: Icons.terrain_outlined,
      ),
      _CategoryProduct(
        name: '连帽卫衣',
        priceLabel: '219',
        icon: Icons.dry_cleaning_outlined,
      ),
    ],
  ),
  _CategorySection(
    label: '鞋靴',
    description: '鞋靴区后面可以继续补热门系列、尺码筛选和穿搭推荐。',
    products: [
      _CategoryProduct(
        name: '轻弹跑鞋',
        priceLabel: '299',
        icon: Icons.hiking_outlined,
      ),
      _CategoryProduct(
        name: '城市通勤板鞋',
        priceLabel: '269',
        icon: Icons.directions_walk_outlined,
      ),
      _CategoryProduct(
        name: '户外登山靴',
        priceLabel: '459',
        icon: Icons.landscape_outlined,
      ),
      _CategoryProduct(
        name: '凉感拖鞋',
        priceLabel: '89',
        icon: Icons.beach_access_outlined,
      ),
    ],
  ),
  _CategorySection(
    label: '箱包',
    description: '箱包页适合继续练习瀑布流、标签角标和商品卡片复用。',
    products: [
      _CategoryProduct(
        name: '极简双肩包',
        priceLabel: '239',
        icon: Icons.work_outline,
      ),
      _CategoryProduct(
        name: '轻商务托特包',
        priceLabel: '199',
        icon: Icons.shopping_bag_outlined,
      ),
      _CategoryProduct(
        name: '旅行收纳包',
        priceLabel: '129',
        icon: Icons.luggage_outlined,
      ),
      _CategoryProduct(
        name: '斜挎马鞍包',
        priceLabel: '269',
        icon: Icons.shopping_bag,
      ),
    ],
  ),
  _CategorySection(
    label: '数码',
    description: '数码分类可以继续扩展成品牌区、参数卡和专题推荐。',
    products: [
      _CategoryProduct(
        name: '主动降噪耳机',
        priceLabel: '699',
        icon: Icons.headphones_outlined,
      ),
      _CategoryProduct(
        name: '便携蓝牙音箱',
        priceLabel: '329',
        icon: Icons.speaker_outlined,
      ),
      _CategoryProduct(
        name: '桌面补光灯',
        priceLabel: '159',
        icon: Icons.light_mode_outlined,
      ),
      _CategoryProduct(
        name: '轻薄平板支架',
        priceLabel: '79',
        icon: Icons.tablet_mac_outlined,
      ),
    ],
  ),
  _CategorySection(
    label: '家居',
    description: '家居分类很适合继续学习更丰富的卡片排版和分组展示。',
    products: [
      _CategoryProduct(
        name: '香薰氛围灯',
        priceLabel: '139',
        icon: Icons.nightlight_outlined,
      ),
      _CategoryProduct(
        name: '云感抱枕',
        priceLabel: '89',
        icon: Icons.weekend_outlined,
      ),
      _CategoryProduct(
        name: '原木置物架',
        priceLabel: '189',
        icon: Icons.inventory_2_outlined,
      ),
      _CategoryProduct(
        name: '陶瓷马克杯',
        priceLabel: '59',
        icon: Icons.coffee_outlined,
      ),
    ],
  ),
  _CategorySection(
    label: '食品',
    description: '食品区后面可以继续补活动标签、组合装和口味筛选。',
    products: [
      _CategoryProduct(
        name: '坚果能量包',
        priceLabel: '49',
        icon: Icons.local_grocery_store_outlined,
      ),
      _CategoryProduct(
        name: '黑巧麦片杯',
        priceLabel: '39',
        icon: Icons.breakfast_dining_outlined,
      ),
      _CategoryProduct(
        name: '冻干水果盒',
        priceLabel: '59',
        icon: Icons.apple_outlined,
      ),
      _CategoryProduct(
        name: '轻食代餐棒',
        priceLabel: '29',
        icon: Icons.cookie_outlined,
      ),
    ],
  ),
];
