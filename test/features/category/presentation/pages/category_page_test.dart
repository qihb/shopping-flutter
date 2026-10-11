import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/features/category/presentation/pages/category_page.dart';
import 'package:my_first_app/features/product/data/models/category_node.dart';
import 'package:my_first_app/features/product/data/models/page_result.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';
import '../../../../helpers/mocks.mocks.dart';
import '../../../../helpers/stub_helpers.dart';

/// 测试用的分类树：服饰带二级分类，鞋靴/数码为一级分类直挂商品。
List<CategoryNode> _buildCategoryTree() {
  return <CategoryNode>[
    buildTestCategory(
      1,
      '服饰',
      children: <CategoryNode>[
        buildTestCategory(11, '男装', parentId: 1),
        buildTestCategory(12, '女装', parentId: 1),
      ],
    ),
    buildTestCategory(2, '鞋靴'),
    buildTestCategory(3, '数码'),
  ];
}

/// 按分类 id 返回固定商品页。
MockProductService _buildProductService({
  bool categoryTreeFails = false,
  bool productsFail = false,
}) {
  final MockProductService service = MockProductService();

  if (categoryTreeFails) {
    when(service.fetchCategoryTree()).thenThrow(StateError('分类树加载失败'));
  } else {
    when(service.fetchCategoryTree())
        .thenAnswer((_) async => _buildCategoryTree());
  }

  when(service.fetchProducts(
    categoryId: anyNamed('categoryId'),
    keyword: anyNamed('keyword'),
    current: anyNamed('current'),
    size: anyNamed('size'),
  )).thenAnswer((Invocation invocation) async {
    if (productsFail) {
      throw StateError('商品加载失败');
    }

    final int? categoryId = invocation.namedArguments[#categoryId] as int?;
    final Map<int, List<ProductSummary>> productsByCategory =
        <int, List<ProductSummary>>{
      11: <ProductSummary>[
        buildTestProduct(101, '男装夹克', categoryId: 11, categoryName: '男装'),
        buildTestProduct(102, '基础款T恤', categoryId: 11, categoryName: '男装'),
      ],
      2: <ProductSummary>[
        buildTestProduct(201, '轻弹跑鞋', categoryId: 2, categoryName: '鞋靴', minPrice: 299),
        buildTestProduct(202, '城市通勤板鞋', categoryId: 2, categoryName: '鞋靴', minPrice: 269),
      ],
    };

    return PageResult<ProductSummary>(
      records: productsByCategory[categoryId] ?? <ProductSummary>[],
      total: (productsByCategory[categoryId] ?? <ProductSummary>[]).length,
      pages: 1,
      current: 1,
      size: 10,
    );
  });

  return service;
}

Widget _buildTestCategoryPage({MockProductService? service}) {
  return MaterialApp(
    home: Scaffold(
      body: CategoryPage(
        productService: service ?? _buildProductService(),
      ),
    ),
  );
}

void main() {
  testWidgets('分类页默认展示左侧一级分类和首个二级分类的商品列表', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestCategoryPage());
    await tester.pumpAndSettle();

    // 左侧一级分类导航。
    expect(find.text('服饰'), findsOneWidget);
    expect(find.text('鞋靴'), findsOneWidget);
    expect(find.text('数码'), findsOneWidget);

    // 默认选中服饰，右侧展示二级分类 chips，并默认选中第一个子分类（男装）。
    // 右侧标题与子分类 chip 都会展示“男装”，共出现两次。
    expect(find.text('男装'), findsNWidgets(2));
    expect(find.text('女装'), findsOneWidget);
    expect(find.text('男装夹克'), findsOneWidget);
    expect(find.text('基础款T恤'), findsOneWidget);
  });

  testWidgets('切换一级分类后右侧商品会按新分类刷新', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestCategoryPage());
    await tester.pumpAndSettle();

    // 鞋靴没有子分类，直接用一级分类 id 查商品。
    await tester.tap(find.text('鞋靴'));
    await tester.pumpAndSettle();

    expect(find.text('轻弹跑鞋'), findsOneWidget);
    expect(find.text('城市通勤板鞋'), findsOneWidget);
    expect(find.text('男装夹克'), findsNothing);
  });

  testWidgets('点击二级分类 chip 会切换右侧商品列表', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestCategoryPage());
    await tester.pumpAndSettle();

    await tester.tap(find.text('女装'));
    await tester.pumpAndSettle();

    // 女装没有配置商品数据，应展示空态而不是继续显示男装商品。
    expect(find.text('该分类下暂时没有商品'), findsOneWidget);
    expect(find.text('男装夹克'), findsNothing);
  });

  testWidgets('分类树加载失败时展示错误态并支持重试', (WidgetTester tester) async {
    final MockProductService service =
        _buildProductService(categoryTreeFails: true);

    await tester.pumpWidget(_buildTestCategoryPage(service: service));
    await tester.pumpAndSettle();

    // 左侧导航与右侧面板会同时渲染错误态，文案各出现一次。
    expect(find.text('分类加载失败，请重试。'), findsNWidgets(2));
    expect(find.text('重试'), findsWidgets);

    // 重试后分类树正常加载。
    when(service.fetchCategoryTree())
        .thenAnswer((_) async => _buildCategoryTree());
    await tester.tap(find.text('重试').first);
    await tester.pumpAndSettle();

    expect(find.text('服饰'), findsOneWidget);
    expect(find.text('男装夹克'), findsOneWidget);
  });

  testWidgets('商品列表加载失败时展示错误态并支持重试', (WidgetTester tester) async {
    final MockProductService service =
        _buildProductService(productsFail: true);

    await tester.pumpWidget(_buildTestCategoryPage(service: service));
    await tester.pumpAndSettle();

    expect(find.text('分类商品加载失败，请重试。'), findsOneWidget);

    when(service.fetchProducts(
      categoryId: anyNamed('categoryId'),
      keyword: anyNamed('keyword'),
      current: anyNamed('current'),
      size: anyNamed('size'),
    )).thenAnswer((Invocation invocation) async {
      final int? categoryId = invocation.namedArguments[#categoryId] as int?;
      return PageResult<ProductSummary>(
        records: <ProductSummary>[
          buildTestProduct(101, '男装夹克', categoryId: categoryId ?? 11),
        ],
        total: 1,
        pages: 1,
        current: 1,
        size: 10,
      );
    });
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(find.text('男装夹克'), findsOneWidget);
  });
}
