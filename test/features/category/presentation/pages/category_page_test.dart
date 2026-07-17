import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/category/presentation/pages/category_page.dart';

void main() {
  testWidgets('分类页默认显示左侧导航和右侧双列瀑布布局', (WidgetTester tester) async {
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

    final Finder firstCard = find.byKey(
      const ValueKey<String>('category-product-运动速干T恤'),
    );
    final Finder secondCard = find.byKey(
      const ValueKey<String>('category-product-轻量防晒衬衫'),
    );
    final Finder thirdCard = find.byKey(
      const ValueKey<String>('category-product-高腰运动短裤'),
    );

    final Offset firstOffset = tester.getTopLeft(firstCard);
    final Offset secondOffset = tester.getTopLeft(secondCard);
    final Offset thirdOffset = tester.getTopLeft(thirdCard);

    expect((firstOffset.dy - secondOffset.dy).abs(), lessThan(1));
    expect(secondOffset.dx, greaterThan(firstOffset.dx));
    expect(thirdOffset.dy, greaterThan(firstOffset.dy));

    final double firstHeight = tester.getSize(firstCard).height;
    final double secondHeight = tester.getSize(secondCard).height;

    expect((firstHeight - secondHeight).abs(), greaterThan(8));
  });
}
