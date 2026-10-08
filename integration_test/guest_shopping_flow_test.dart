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

void main() {
  patrolTest('游客从首页浏览商品到加入购物车的完整闭环', ($) async {
    // ---------- 启动：复刻 bootstrap 的配置装载 ----------
    // Patrol 环境下不能调用 WidgetsFlutterBinding.ensureInitialized()
    // （patrol 已完成初始化），也不能走 bootstrap()/runApp()，
    // 改用 $.pumpWidget 挂载根组件，配置装载步骤与 bootstrap 保持一致。
    AppConfigStore.setConfig(await AppConfigLoader().load());
    await $.pumpWidget(const MyApp());

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

    // ---------- 详情页：加入购物车 ----------
    // 点击后应用自身会 pop 回主页并切换到购物车 tab（MainTabPage 行为）。
    await card.tap(settleTimeout: _quickSettle);
    await $(const ValueKey<String>('product-detail-add-to-cart')).tap(
      settleTimeout: _quickSettle,
    );

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
}
