import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/app/presentation/pages/main_tab_page.dart';

void main() {
  testWidgets('从首页点击分类入口后会切到分类页并选中对应分类', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainTabPage(),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('鞋靴'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('鞋靴').first);
    await tester.pumpAndSettle();

    expect(find.text('轻弹跑鞋'), findsOneWidget);
    expect(find.text('城市通勤板鞋'), findsOneWidget);
  });

  testWidgets('从商品详情加入购物车后会在购物车页看到对应商品', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainTabPage(),
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

    await tester.tap(find.text('加入购物车'));
    await tester.pumpAndSettle();

    expect(find.text('夏季轻运动鞋'), findsOneWidget);
    expect(find.text('EUR 89'), findsOneWidget);
    expect(find.text('合计 EUR 89'), findsOneWidget);
  });

  testWidgets('购物车里修改商品数量后会同步更新数量和合计金额', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainTabPage(),
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

    await tester.tap(find.text('加入购物车'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('cart-increase-夏季轻运动鞋')),
    );
    await tester.pumpAndSettle();

    expect(find.text('数量 x2'), findsOneWidget);
    expect(find.text('合计 EUR 178'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('cart-decrease-夏季轻运动鞋')),
    );
    await tester.pumpAndSettle();

    expect(find.text('数量 x1'), findsOneWidget);
    expect(find.text('合计 EUR 89'), findsOneWidget);
  });

  testWidgets('从购物车提交订单后会生成订单并在我的页面显示状态', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainTabPage(),
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

    await tester.tap(find.text('加入购物车'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('提交订单'));
    await tester.pumpAndSettle();

    expect(find.text('最近订单'), findsOneWidget);
    expect(find.text('订单状态'), findsWidgets);
    expect(find.text('待发货'), findsWidgets);
    expect(find.text('夏季轻运动鞋'), findsOneWidget);
  });

  testWidgets('我的页面切换基础设置后会更新当前状态文案', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainTabPage(),
      ),
    );

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.text('消息通知: 已开启'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('profile-setting-notification')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('profile-setting-notification')),
    );
    await tester.pumpAndSettle();

    expect(find.text('消息通知: 已关闭'), findsOneWidget);
  });

  testWidgets('从分类页进入详情并加入购物车后会在购物车看到商品', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainTabPage(),
      ),
    );

    await tester.tap(find.text('分类'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('鞋靴'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('category-product-轻弹跑鞋')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('category-product-轻弹跑鞋')),
    );
    await tester.pumpAndSettle();

    expect(find.text('商品详情'), findsOneWidget);
    expect(find.text('轻弹跑鞋'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('加入购物车'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('加入购物车'));
    await tester.pumpAndSettle();

    expect(find.text('轻弹跑鞋'), findsOneWidget);
    expect(find.text('合计 EUR 299'), findsOneWidget);
  });
}
