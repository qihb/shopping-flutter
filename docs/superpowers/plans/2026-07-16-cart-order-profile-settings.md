# 购物车下单与我的页面实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让当前 Flutter 电商项目具备“购物车提交订单 -> 我的页面查看订单状态、个人信息和基础设置”的最小可用闭环。

**Architecture:** 继续沿用 `MainTabPage` 作为当前阶段的轻量状态承接点，不引入额外状态管理库。购物车、订单、个人资料和基础设置都先用本地内存状态组织，再通过 `CartPage` 和 `ProfilePage` 负责展示与交互回调。

**Tech Stack:** Flutter Material、Widget Test、现有 `IndexedStack` 主页面结构

---

### Task 1: 打通购物车提交订单主链路

**Files:**
- Modify: `lib/app/presentation/pages/main_tab_page.dart`
- Modify: `lib/features/cart/presentation/pages/cart_page.dart`
- Create: `lib/features/order/presentation/models/order_record.dart`
- Test: `test/app/presentation/pages/main_tab_page_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('从购物车提交订单后会生成订单并在我的页面显示状态', (WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

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
  expect(find.text('订单状态'), findsOneWidget);
  expect(find.text('待发货'), findsOneWidget);
  expect(find.text('夏季轻运动鞋'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/presentation/pages/main_tab_page_test.dart --plain-name "从购物车提交订单后会生成订单并在我的页面显示状态"`

Expected: FAIL，因为当前购物车页还没有提交订单动作，也没有订单展示区域。

- [ ] **Step 3: Write minimal implementation**

```dart
class OrderRecord {
  const OrderRecord({
    required this.id,
    required this.items,
    required this.statusLabel,
    required this.totalPriceLabel,
  });
}

void _submitCartAsOrder() {
  setState(() {
    _orders.insert(0, OrderRecord.fromCartItems(_cartItems));
    _cartItems.clear();
    _currentIndex = 3;
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/app/presentation/pages/main_tab_page_test.dart --plain-name "从购物车提交订单后会生成订单并在我的页面显示状态"`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/app/presentation/pages/main_tab_page_test.dart lib/app/presentation/pages/main_tab_page.dart lib/features/cart/presentation/pages/cart_page.dart lib/features/order/presentation/models/order_record.dart
git commit -m "$(cat <<'EOF'
feat: add checkout flow to generate mock orders
EOF
)"
```

### Task 2: 实现我的页面的个人信息与订单状态区块

**Files:**
- Modify: `lib/features/profile/presentation/pages/profile_page.dart`
- Modify: `lib/app/presentation/pages/main_tab_page.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('我的页面会展示个人信息和订单状态概览', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());

  await tester.tap(find.text('我的'));
  await tester.pumpAndSettle();

  expect(find.text('Hi, Qi Hai Bing'), findsOneWidget);
  expect(find.text('订单状态'), findsOneWidget);
  expect(find.text('待付款'), findsOneWidget);
  expect(find.text('待发货'), findsOneWidget);
  expect(find.text('基础设置'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart --plain-name "我的页面会展示个人信息和订单状态概览"`

Expected: FAIL，因为当前我的页面还是占位页。

- [ ] **Step 3: Write minimal implementation**

```dart
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.profile,
    required this.orders,
    required this.settings,
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart --plain-name "我的页面会展示个人信息和订单状态概览"`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/widget_test.dart lib/features/profile/presentation/pages/profile_page.dart lib/app/presentation/pages/main_tab_page.dart
git commit -m "$(cat <<'EOF'
feat: build profile page with profile and order summary
EOF
)"
```

### Task 3: 补齐基础设置交互

**Files:**
- Modify: `lib/features/profile/presentation/pages/profile_page.dart`
- Modify: `lib/app/presentation/pages/main_tab_page.dart`
- Test: `test/app/presentation/pages/main_tab_page_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('我的页面切换基础设置后会更新当前状态文案', (WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: MainTabPage()));

  await tester.tap(find.text('我的'));
  await tester.pumpAndSettle();

  expect(find.text('消息通知: 已开启'), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey<String>('profile-setting-notification')));
  await tester.pumpAndSettle();
  expect(find.text('消息通知: 已关闭'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/presentation/pages/main_tab_page_test.dart --plain-name "我的页面切换基础设置后会更新当前状态文案"`

Expected: FAIL，因为当前设置区还没有交互。

- [ ] **Step 3: Write minimal implementation**

```dart
SwitchListTile(
  key: const ValueKey<String>('profile-setting-notification'),
  value: settings.enableNotification,
  onChanged: onNotificationChanged,
)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/app/presentation/pages/main_tab_page_test.dart --plain-name "我的页面切换基础设置后会更新当前状态文案"`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/app/presentation/pages/main_tab_page_test.dart lib/features/profile/presentation/pages/profile_page.dart lib/app/presentation/pages/main_tab_page.dart
git commit -m "$(cat <<'EOF'
feat: add basic profile settings toggles
EOF
)"
```

### Task 4: 运行完整验证并同步测试文案

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `test/app/presentation/pages/main_tab_page_test.dart`

- [ ] **Step 1: Run focused test suites**

Run:

```bash
flutter test test/app/presentation/pages/main_tab_page_test.dart
flutter test test/widget_test.dart
```

Expected: PASS

- [ ] **Step 2: Run full project validation**

Run:

```bash
flutter analyze
flutter test
```

Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add test/widget_test.dart test/app/presentation/pages/main_tab_page_test.dart
git commit -m "$(cat <<'EOF'
test: cover order creation and profile settings flow
EOF
)"
```
