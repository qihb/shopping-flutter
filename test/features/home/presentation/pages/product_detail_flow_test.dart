import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/home/presentation/pages/home_page.dart';
import 'package:my_first_app/features/product/data/models/product_sku.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';
import '../../../../helpers/mocks.mocks.dart';
import '../../../../helpers/stub_helpers.dart';

/// 创建已打桩的商品服务：分页返回固定商品，详情按商品 id 返回对应数据。
MockProductService _buildProductService() {
  final MockProductService service = MockProductService();
  stubProductPage(
    service,
    products: <ProductSummary>[
      buildTestProduct(1, '夏季轻运动鞋'),
      buildTestProduct(2, '极简双肩包', minPrice: 129),
    ],
  );
  stubProductDetail(
    service,
    buildTestProductDetail(
      1,
      '夏季轻运动鞋',
      skus: const <ProductSku>[
        ProductSku(
          id: 9,
          skuCode: 'SKU-009',
          specs: '白色 / 42 码',
          price: 89,
          originalPrice: 129,
          stock: 50,
          status: 1,
        ),
      ],
    ),
  );
  return service;
}

Widget _buildTestHome() {
  return MaterialApp(
    home: Scaffold(
      body: HomePage(
        productService: _buildProductService(),
      ),
    ),
  );
}

void main() {
  testWidgets('点击首页推荐商品后会进入商品详情页', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestHome());

    await tester.pump(const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(
      find.text('夏季轻运动鞋'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('夏季轻运动鞋'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('加入购物车'),
      200,
      // 主滚动视图是树中第一个 Scrollable，末尾的 Scrollable 属于 SKU 横滑列表。
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('商品详情'), findsOneWidget);
    expect(find.text('夏季轻运动鞋'), findsWidgets);
    expect(find.text('加入购物车'), findsOneWidget);
    // 详情页压栈后首页处于 offstage，finder 只统计详情页内的价格：
    // 价格区展示商品最低价，选中 SKU 高于现价时附带划线价。
    expect(find.text('¥89'), findsOneWidget);
    expect(find.text('¥129'), findsOneWidget);
    expect(find.text('白色 / 42 码'), findsOneWidget);
  });
}
