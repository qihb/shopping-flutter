import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/home/presentation/pages/home_page.dart';
import '../../../../helpers/mocks.mocks.dart';
import '../../../../helpers/stub_helpers.dart';

/// 创建已打桩的推荐服务：按页返回生产 mock 数据。
MockHomeRecommendService _buildRecommendService() {
  final MockHomeRecommendService service = MockHomeRecommendService();
  stubRecommendFromMockData(service);
  return service;
}

Widget _buildTestHome() {
  return MaterialApp(
    home: Scaffold(
      body: HomePage(
        recommendService: _buildRecommendService(),
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
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('商品详情'), findsOneWidget);
    expect(find.text('夏季轻运动鞋'), findsWidgets);
    expect(find.text('加入购物车'), findsOneWidget);
  });
}
