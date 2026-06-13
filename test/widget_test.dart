// 这是一个基础的 Flutter Widget 测试文件。
//
// `WidgetTester` 可以帮助你在测试环境里渲染组件、查找节点、
// 模拟点击和滚动，并验证页面上最终显示的内容是否符合预期。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/app/app.dart';

void main() {
  testWidgets('应用启动后可以渲染当前首页骨架', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('首页模块占位页'), findsOneWidget);
    expect(find.text('这个页面是后续业务组件、页面分区和状态管理接入的起点。'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
