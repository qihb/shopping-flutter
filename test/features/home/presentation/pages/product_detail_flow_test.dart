import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/features/home/data/home_recommend_mock_service.dart';
import 'package:my_first_app/features/home/data/home_recommend_service.dart';
import 'package:my_first_app/features/home/presentation/models/home_recommend_product.dart';
import 'package:my_first_app/features/home/presentation/pages/home_page.dart';

/// 测试用的推荐服务，封装原有的 mock 数据。
class _TestRecommendService extends HomeRecommendService {
  final HomeRecommendMockService _mockService;

  _TestRecommendService({required super.apiClient})
      : _mockService = const HomeRecommendMockService();

  @override
  Future<HomeRecommendPageResult> fetchRecommendProducts({
    required int page,
  }) async {
    return _mockService.fetchRecommendProducts(page: page);
  }
}

Widget _buildTestHome() {
  return MaterialApp(
    home: Scaffold(
      body: HomePage(
        recommendService: _TestRecommendService(
          apiClient: ApiClient(baseUrl: 'https://test.local'),
        ),
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
