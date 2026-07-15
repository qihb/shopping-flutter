import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/home/presentation/pages/home_page.dart';

void main() {
  testWidgets('点击首页推荐商品后会进入商品详情页', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomePage(),
        ),
      ),
    );

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
