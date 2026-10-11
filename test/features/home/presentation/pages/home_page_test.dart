import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/features/home/presentation/pages/home_page.dart';
import 'package:my_first_app/features/product/data/models/category_node.dart';
import 'package:my_first_app/features/product/data/models/page_result.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';
import '../../../../helpers/mocks.mocks.dart';
import '../../../../helpers/stub_helpers.dart';

/// 创建已打桩的商品服务：分页固定返回两页数据，分类树返回空列表。
MockProductService _buildProductService() {
  final MockProductService service = MockProductService();
  when(service.fetchProducts(
    categoryId: anyNamed('categoryId'),
    keyword: anyNamed('keyword'),
    current: anyNamed('current'),
    size: anyNamed('size'),
  )).thenAnswer((Invocation invocation) async {
    final int current = invocation.namedArguments[#current] as int;

    if (current <= 1) {
      return PageResult<ProductSummary>(
        records: <ProductSummary>[
          buildTestProduct(1, '夏季轻运动鞋'),
          buildTestProduct(2, '极简双肩包', minPrice: 129),
        ],
        total: 3,
        pages: 2,
        current: 1,
        size: 2,
      );
    }

    return PageResult<ProductSummary>(
      records: <ProductSummary>[
        buildTestProduct(3, '防晒渔夫帽', minPrice: 39),
      ],
      total: 3,
      pages: 2,
      current: 2,
      size: 2,
    );
  });
  when(service.fetchCategoryTree())
      .thenAnswer((_) async => <CategoryNode>[]);
  return service;
}

Widget _buildTestHome({MockProductService? service}) {
  return MaterialApp(
    home: Scaffold(
      body: HomePage(
        productService: service ?? _buildProductService(),
      ),
    ),
  );
}

void main() {
  testWidgets('首页推荐区滚动到底部后会加载下一页商品', (WidgetTester tester) async {
    // 用 Completer 挂起第二页响应，才能稳定捕捉“加载更多”中间态。
    final Completer<void> secondPageGate = Completer<void>();
    final MockProductService service = _buildProductService();
    when(service.fetchProducts(
      categoryId: anyNamed('categoryId'),
      keyword: anyNamed('keyword'),
      current: 2,
      size: anyNamed('size'),
    )).thenAnswer((_) async {
      await secondPageGate.future;
      return PageResult<ProductSummary>(
        records: <ProductSummary>[
          buildTestProduct(3, '防晒渔夫帽', minPrice: 39),
        ],
        total: 3,
        pages: 2,
        current: 2,
        size: 2,
      );
    });

    await tester.pumpWidget(_buildTestHome(service: service));

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('防晒渔夫帽'), findsNothing);

    await tester.fling(find.byType(Scrollable).first, const Offset(0, -800), 1600);
    // 第一帧触发滚动监听发起请求，第二帧重建出加载更多指示器。
    await tester.pump();
    await tester.pump();

    expect(find.text('正在加载更多推荐商品...'), findsOneWidget);

    secondPageGate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('防晒渔夫帽'), findsOneWidget);
    expect(find.text('正在加载更多推荐商品...'), findsNothing);
  });

  testWidgets('往上滚动时为你推荐标题到顶部后会保持吸顶', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestHome());

    await tester.pump(const Duration(milliseconds: 500));

    await tester.scrollUntilVisible(
      find.text('为你推荐'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(Scrollable).first, const Offset(0, -300), 1200);
    await tester.pumpAndSettle();

    expect(find.text('为你推荐'), findsOneWidget);

    final double titleTop = tester.getTopLeft(find.text('为你推荐')).dy;
    expect(titleTop, lessThanOrEqualTo(32));
  });

  testWidgets('下拉刷新会让推荐区回到第一页并重置首页轮播图', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestHome());

    await tester.pump(const Duration(milliseconds: 500));

    await tester.fling(
      find.byType(PageView),
      const Offset(-400, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('城市夏日穿搭'), findsOneWidget);

    await tester.fling(find.byType(Scrollable).first, const Offset(0, -800), 1600);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('防晒渔夫帽'), findsOneWidget);

    await tester.fling(find.byType(Scrollable).first, const Offset(0, 1200), 1800);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('防晒渔夫帽'), findsNothing);
    expect(find.text('露营装备开箱'), findsWidgets);
    expect(find.text('城市夏日穿搭'), findsNothing);
  });
}
