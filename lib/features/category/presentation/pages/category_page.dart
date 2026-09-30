import 'package:flutter/material.dart';

import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';
import 'package:my_first_app/features/home/presentation/pages/product_detail_page.dart';

/// 分类页。
///
/// 采用“左侧分类导航 + 右侧商品网格”的双栏结构，
/// 这是电商 App 常见的分类页组织方式。
///
/// 左侧展示当前浏览的大类目录，右侧展示对应分类下的商品卡片列表，
/// 后续可继续接入筛选、二级分类与真实数据。
class CategoryPage extends StatefulWidget {
  /// 承接“从首页点击某个分类后，分类页默认选中哪个分类”，
  /// 等价于进入页面时携带的初始筛选条件。
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
      description: '${section.label}分类精选单品。',
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
            // `Expanded` 占满 `Row` 剩余空间，让右侧内容区铺满。
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
                    sliver: SliverToBoxAdapter(
                      child: _CategoryWaterfallSection(
                        section: activeSection,
                        onProductTap: (product) => _openProductDetail(
                          section: activeSection,
                          product: product,
                        ),
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
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: product.artworkHeight,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(product.icon, color: colorScheme.primary),
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
              product.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'EUR ${product.priceLabel}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryWaterfallSection extends StatelessWidget {
  final _CategorySection section;
  final ValueChanged<_CategoryProduct> onProductTap;

  const _CategoryWaterfallSection({
    required this.section,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<_CategoryProduct> leftColumnProducts = <_CategoryProduct>[];
    final List<_CategoryProduct> rightColumnProducts = <_CategoryProduct>[];

    for (int index = 0; index < section.products.length; index += 1) {
      final _CategoryProduct product = section.products[index];

      if (index.isEven) {
        leftColumnProducts.add(product);
      } else {
        rightColumnProducts.add(product);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _CategoryWaterfallColumn(products: leftColumnProducts, onProductTap: onProductTap)),
        const SizedBox(width: 12),
        Expanded(child: _CategoryWaterfallColumn(products: rightColumnProducts, onProductTap: onProductTap)),
      ],
    );
  }
}

class _CategoryWaterfallColumn extends StatelessWidget {
  final List<_CategoryProduct> products;
  final ValueChanged<_CategoryProduct> onProductTap;

  const _CategoryWaterfallColumn({
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: products
          .map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryProductCard(
                product: product,
                onTap: () => onProductTap(product),
              ),
            ),
          )
          .toList(growable: false),
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
  final String subtitle;
  final String priceLabel;
  final IconData icon;
  final double artworkHeight;

  const _CategoryProduct({
    required this.name,
    required this.subtitle,
    required this.priceLabel,
    required this.icon,
    required this.artworkHeight,
  });
}

const List<_CategorySection> _categorySections = [
  _CategorySection(
    label: '服饰',
    description: '精选上装、下装与基础单品，覆盖日常通勤与运动穿搭。',
    products: [
      _CategoryProduct(
        name: '运动速干T恤',
        subtitle: '透气面料，适合日常训练',
        priceLabel: '129',
        icon: Icons.checkroom_outlined,
        artworkHeight: 156,
      ),
      _CategoryProduct(
        name: '轻量防晒衬衫',
        subtitle: '轻薄外搭，适合通勤与出游',
        priceLabel: '169',
        icon: Icons.sunny_snowing,
        artworkHeight: 124,
      ),
      _CategoryProduct(
        name: '高腰运动短裤',
        subtitle: '高腰包裹版型，活动更自在',
        priceLabel: '149',
        icon: Icons.directions_run_outlined,
        artworkHeight: 144,
      ),
      _CategoryProduct(
        name: '针织背心',
        subtitle: '适合做夏季叠穿的基础单品',
        priceLabel: '99',
        icon: Icons.style_outlined,
        artworkHeight: 178,
      ),
      _CategoryProduct(
        name: '基础款牛仔裤',
        subtitle: '直筒版型，容易搭配通勤造型',
        priceLabel: '199',
        icon: Icons.shopping_bag_outlined,
        artworkHeight: 138,
      ),
      _CategoryProduct(
        name: '夏日牛仔外套',
        subtitle: '轻丹宁面料，适合空调房外搭',
        priceLabel: '239',
        icon: Icons.iron_outlined,
        artworkHeight: 168,
      ),
      _CategoryProduct(
        name: '棉质半身裙',
        subtitle: '柔软棉质，日常穿着更舒适',
        priceLabel: '159',
        icon: Icons.terrain_outlined,
        artworkHeight: 132,
      ),
      _CategoryProduct(
        name: '连帽卫衣',
        subtitle: '适合春秋通勤的百搭层次单品',
        priceLabel: '219',
        icon: Icons.dry_cleaning_outlined,
        artworkHeight: 182,
      ),
    ],
  ),
  _CategorySection(
    label: '鞋靴',
    description: '精选跑鞋、板鞋与户外鞋款，满足通勤与户外场景。',
    products: [
      _CategoryProduct(
        name: '轻弹跑鞋',
        subtitle: '轻盈缓震，适合通勤和慢跑',
        priceLabel: '299',
        icon: Icons.hiking_outlined,
        artworkHeight: 156,
      ),
      _CategoryProduct(
        name: '城市通勤板鞋',
        subtitle: '简洁鞋型，适合日常搭配',
        priceLabel: '269',
        icon: Icons.directions_walk_outlined,
        artworkHeight: 128,
      ),
      _CategoryProduct(
        name: '户外登山靴',
        subtitle: '加固鞋帮，适合周末徒步',
        priceLabel: '459',
        icon: Icons.landscape_outlined,
        artworkHeight: 176,
      ),
      _CategoryProduct(
        name: '凉感拖鞋',
        subtitle: '柔软脚感，适合居家与短途外出',
        priceLabel: '89',
        icon: Icons.beach_access_outlined,
        artworkHeight: 138,
      ),
    ],
  ),
  _CategorySection(
    label: '箱包',
    description: '精选双肩包、托特包与收纳包，覆盖通勤、商务与旅行场景。',
    products: [
      _CategoryProduct(
        name: '极简双肩包',
        subtitle: '多层收纳，兼顾日常与短途',
        priceLabel: '239',
        icon: Icons.work_outline,
        artworkHeight: 164,
      ),
      _CategoryProduct(
        name: '轻商务托特包',
        subtitle: '适合办公室与轻商务场景',
        priceLabel: '199',
        icon: Icons.shopping_bag_outlined,
        artworkHeight: 140,
      ),
      _CategoryProduct(
        name: '旅行收纳包',
        subtitle: '分类收纳更清晰',
        priceLabel: '129',
        icon: Icons.luggage_outlined,
        artworkHeight: 126,
      ),
      _CategoryProduct(
        name: '斜挎马鞍包',
        subtitle: '小巧包型，适合日常轻出行',
        priceLabel: '269',
        icon: Icons.shopping_bag,
        artworkHeight: 174,
      ),
    ],
  ),
  _CategorySection(
    label: '数码',
    description: '精选耳机、音箱与桌面数码配件，提升影音与办公体验。',
    products: [
      _CategoryProduct(
        name: '主动降噪耳机',
        subtitle: '沉浸式降噪体验，适合通勤',
        priceLabel: '699',
        icon: Icons.headphones_outlined,
        artworkHeight: 162,
      ),
      _CategoryProduct(
        name: '便携蓝牙音箱',
        subtitle: '小体积也能有不错外放表现',
        priceLabel: '329',
        icon: Icons.speaker_outlined,
        artworkHeight: 132,
      ),
      _CategoryProduct(
        name: '桌面补光灯',
        subtitle: '提升桌面拍摄和视频会议亮度',
        priceLabel: '159',
        icon: Icons.light_mode_outlined,
        artworkHeight: 148,
      ),
      _CategoryProduct(
        name: '轻薄平板支架',
        subtitle: '看剧和办公都更省力',
        priceLabel: '79',
        icon: Icons.tablet_mac_outlined,
        artworkHeight: 120,
      ),
    ],
  ),
  _CategorySection(
    label: '家居',
    description: '精选香薰、抱枕与收纳好物，营造舒适居家氛围。',
    products: [
      _CategoryProduct(
        name: '香薰氛围灯',
        subtitle: '适合卧室和桌面营造氛围',
        priceLabel: '139',
        icon: Icons.nightlight_outlined,
        artworkHeight: 168,
      ),
      _CategoryProduct(
        name: '云感抱枕',
        subtitle: '柔软支撑感，适合沙发与卧室',
        priceLabel: '89',
        icon: Icons.weekend_outlined,
        artworkHeight: 132,
      ),
      _CategoryProduct(
        name: '原木置物架',
        subtitle: '轻松整理桌面与玄关小物',
        priceLabel: '189',
        icon: Icons.inventory_2_outlined,
        artworkHeight: 154,
      ),
      _CategoryProduct(
        name: '陶瓷马克杯',
        subtitle: '日常咖啡和茶饮都适合',
        priceLabel: '59',
        icon: Icons.coffee_outlined,
        artworkHeight: 122,
      ),
    ],
  ),
  _CategorySection(
    label: '食品',
    description: '精选坚果、麦片与代餐零食，适合通勤与日常补给。',
    products: [
      _CategoryProduct(
        name: '坚果能量包',
        subtitle: '适合通勤和加班时补充能量',
        priceLabel: '49',
        icon: Icons.local_grocery_store_outlined,
        artworkHeight: 144,
      ),
      _CategoryProduct(
        name: '黑巧麦片杯',
        subtitle: '早餐或下午茶都方便',
        priceLabel: '39',
        icon: Icons.breakfast_dining_outlined,
        artworkHeight: 130,
      ),
      _CategoryProduct(
        name: '冻干水果盒',
        subtitle: '口感轻脆，适合随手分享',
        priceLabel: '59',
        icon: Icons.apple_outlined,
        artworkHeight: 160,
      ),
      _CategoryProduct(
        name: '轻食代餐棒',
        subtitle: '适合户外与忙碌通勤场景',
        priceLabel: '29',
        icon: Icons.cookie_outlined,
        artworkHeight: 118,
      ),
    ],
  ),
];
