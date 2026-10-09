import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/app/app.dart';
import 'package:my_first_app/app/config/app_config_loader.dart';
import 'package:my_first_app/app/config/app_config_store.dart';
import 'package:my_first_app/features/cart/presentation/pages/cart_page.dart';
import 'package:patrol/patrol.dart';

/// Banner 轮播里的视频会持续产生新帧，页面永远不会完全"静止"。
/// patrol 默认的 settle 策略是 trySettle：超时后继续往下执行而不是判失败。
/// 这里给每个 settle 步骤配一个较短超时，避免每步白等默认的 10 秒。
const Duration _quickSettle = Duration(seconds: 3);

/// 商品卡片的 InkWell 上带有 `home-product-card-<商品名>` 形态的 key。
/// 商品数据来自 FakeStore 公网接口，商品名编译期不可知，
/// 所以这里用谓词匹配所有商品卡片，而不是写死某个商品名。
Finder _productCardFinder() => find.byWidgetPredicate(
  (Widget widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('home-product-card-'),
);

/// 订单卡片 key `order-record-card-<订单号>`、推进按钮 key
/// `order-advance-<订单号>` 里的订单号由应用运行期生成，
/// 同样按 key 前缀做谓词匹配。
Finder _finderWithKeyPrefix(String prefix) => find.byWidgetPredicate(
  (Widget widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(prefix),
);

/// 启动应用并挂载根组件。
///
/// Patrol 环境下不能调用 WidgetsFlutterBinding.ensureInitialized()
/// （patrol 已完成初始化），也不能走 bootstrap()/runApp()，
/// 改用 $.pumpWidget 挂载根组件，配置装载步骤与 bootstrap 保持一致。
/// 各用例各自 pump 一份全新的组件树，Provider 状态互不残留。
Future<void> _launchApp(PatrolIntegrationTester $) async {
  AppConfigStore.setConfig(await AppConfigLoader().load());
  await $.pumpWidget(const MyApp());
}

/// 从首页进入第一个商品详情并加入购物车。
///
/// 返回从卡片 key 反解出的商品名，供后续断言使用；
/// 加购后应用会自动切到购物车 tab（MainTabPage 行为）。
Future<String> _addFirstProductToCart(PatrolIntegrationTester $) async {
  // 推荐商品来自公网 FakeStore 接口，scrollUntilVisible 内部会
  // 先等卡片可点击（已可见则不滚动），不可见则逐段滚动直到可点击。
  final card = await $.scrollUntilVisible(
    finder: _productCardFinder(),
    delta: 150,
    settleBetweenScrollsTimeout: _quickSettle,
  );

  // 卡片 InkWell 的 key 是 'home-product-card-<商品名>'，
  // 从 key 还原商品名，稍后在购物车页断言同一件商品，证明闭环成立。
  final tappedCard = $.tester.widget<InkWell>(card);
  final productName = (tappedCard.key! as ValueKey<String>)
      .value
      .replaceFirst('home-product-card-', '');

  await card.tap(settleTimeout: _quickSettle);
  await $(const ValueKey<String>('product-detail-add-to-cart')).tap(
    settleTimeout: _quickSettle,
  );
  return productName;
}

void main() {
  patrolTest('游客从首页浏览商品到加入购物车的完整闭环', ($) async {
    await _launchApp($);
    final productName = await _addFirstProductToCart($);

    // ---------- 购物车：角标计数 ----------
    // 底部导航的购物车角标 key 挂在 Container 上，
    // 需要下钻到子树里的 Text 才能读到数字。
    expect(
      $(const ValueKey<String>('cart-tab-badge')).$(Text).text,
      '1',
    );

    // ---------- 购物车：商品内容 ----------
    // MainTabPage 用 IndexedStack 承载四个 tab，首页商品卡片
    // 与购物车条目会存在同名文本，因此把断言限定在 CartPage 子树内，
    // 证明加购的商品确实进入了购物车数据。
    expect(
      $(find.descendant(
        of: find.byType(CartPage),
        matching: find.text(productName),
      )),
      findsOneWidget,
    );
  });

  patrolTest('游客在购物车里增加、减少数量并删除商品', ($) async {
    await _launchApp($);
    final productName = await _addFirstProductToCart($);

    // ---------- 增加数量：角标 1 -> 2 ----------
    await $(ValueKey<String>('cart-increase-$productName')).tap(
      settleTimeout: _quickSettle,
    );
    expect(
      $(const ValueKey<String>('cart-tab-badge')).$(Text).text,
      '2',
    );
    // 商品卡上的“数量 x2”文案与底部导航角标是两处独立渲染，
    // 同时断言防止其中一处漏更新。
    expect(
      $(find.descendant(
        of: find.byType(CartPage),
        matching: find.text('数量 x2'),
      )),
      findsOneWidget,
    );

    // ---------- 减少数量：角标 2 -> 1 ----------
    await $(ValueKey<String>('cart-decrease-$productName')).tap(
      settleTimeout: _quickSettle,
    );
    expect(
      $(const ValueKey<String>('cart-tab-badge')).$(Text).text,
      '1',
    );

    // ---------- 删除商品：回到空购物车 ----------
    await $(ValueKey<String>('cart-delete-$productName')).tap(
      settleTimeout: _quickSettle,
    );
    expect($(find.text('购物车还是空的')), findsOneWidget);
    // 角标只在 itemCount > 0 时渲染，清空后应从组件树消失
    expect($(const ValueKey<String>('cart-tab-badge')), findsNothing);
  });

  patrolTest('游客提交订单完成模拟支付并推进订单状态', ($) async {
    await _launchApp($);
    await _addFirstProductToCart($);

    // ---------- 购物车 -> 订单确认页 ----------
    await $(const ValueKey<String>('cart-submit-order')).tap(
      settleTimeout: _quickSettle,
    );

    // 订单确认页默认选中支付宝，这里切到微信支付，验证单选交互可用
    await $(const ValueKey<String>('payment-method-wechat')).tap(
      settleTimeout: _quickSettle,
    );

    // 确认支付：配置里 enableRealPayment=false，
    // 走 MockPaymentGateway 立即返回成功，不会拉起真实支付 SDK。
    // 成功后确认页 pop、切到“我的” tab、购物车清空。
    await $(const ValueKey<String>('order-confirm-pay')).tap(
      settleTimeout: _quickSettle,
    );
    expect($(const ValueKey<String>('cart-tab-badge')), findsNothing);

    // 支付成功订单自动推进到“待发货”，从“我的”页状态入口打开订单记录页
    await $(const ValueKey<String>('profile-order-status-待发货')).tap(
      settleTimeout: _quickSettle,
    );
    expect(_finderWithKeyPrefix('order-record-card-'), findsOneWidget);

    // ---------- 推进订单状态：待发货 -> 待收货 ----------
    await $(_finderWithKeyPrefix('order-advance-')).tap(
      settleTimeout: _quickSettle,
    );
    // 状态推进后不再满足“待发货”筛选条件，订单卡片应从列表消失
    expect(_finderWithKeyPrefix('order-record-card-'), findsNothing);
  });
}
