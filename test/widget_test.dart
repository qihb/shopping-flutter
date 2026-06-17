// 这是一个基础的 Flutter Widget 测试文件。
//
// `WidgetTester` 可以帮助你在测试环境里渲染组件、查找节点、
// 模拟点击和滚动，并验证页面上最终显示的内容是否符合预期。

import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/app/app.dart';

void main() {
  testWidgets('应用启动后显示 4 个底部导航菜单并默认停留在首页', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('分类'), findsOneWidget);
    expect(find.text('购物车'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('首页内容建设中'), findsOneWidget);
  });

  testWidgets('点击底部导航后可以切换到对应占位页面', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('分类'));
    await tester.pumpAndSettle();
    expect(find.text('分类内容建设中'), findsOneWidget);

    await tester.tap(find.text('购物车'));
    await tester.pumpAndSettle();
    expect(find.text('购物车内容建设中'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('我的内容建设中'), findsOneWidget);
  });
}
