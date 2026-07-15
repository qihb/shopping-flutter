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
}
