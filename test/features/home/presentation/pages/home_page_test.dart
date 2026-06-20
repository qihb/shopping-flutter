import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/home/presentation/pages/home_page.dart';

void main() {
  testWidgets('首页推荐区滚动到底部后会加载下一页 mock 商品', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomePage(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('防晒渔夫帽'), findsNothing);

    await tester.fling(find.byType(Scrollable).first, const Offset(0, -800), 1600);
    await tester.pump();

    expect(find.text('正在加载更多推荐商品...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('防晒渔夫帽'), findsOneWidget);
    expect(find.text('正在加载更多推荐商品...'), findsNothing);
  });

  testWidgets('往上滚动时为你推荐标题到顶部后会保持吸顶', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomePage(),
        ),
      ),
    );

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
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomePage(),
        ),
      ),
    );

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
