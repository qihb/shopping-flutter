import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/category/presentation/pages/category_page.dart';

void main() {
  testWidgets('分类页默认显示左侧导航和右侧四列商品网格', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryPage(),
        ),
      ),
    );

    expect(find.text('服饰'), findsWidgets);
    expect(find.text('鞋靴'), findsOneWidget);
    expect(find.text('运动速干T恤'), findsOneWidget);
    expect(find.text('轻量防晒衬衫'), findsOneWidget);
    expect(find.text('高腰运动短裤'), findsOneWidget);
    expect(find.text('针织背心'), findsOneWidget);
    expect(find.text('基础款牛仔裤'), findsOneWidget);

    final double firstRowTop = tester
        .getTopLeft(find.text('运动速干T恤'))
        .dy;
    final double fourthRowTop = tester
        .getTopLeft(find.text('针织背心'))
        .dy;
    final double fifthRowTop = tester
        .getTopLeft(find.text('基础款牛仔裤'))
        .dy;

    expect((firstRowTop - fourthRowTop).abs(), lessThan(1));
    expect(fifthRowTop, greaterThan(firstRowTop));
  });
}
