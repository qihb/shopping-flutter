import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/app/app.dart';
import 'package:my_first_app/app/config/app_config_loader.dart';
import 'package:my_first_app/app/config/app_config_store.dart';
import 'package:my_first_app/features/auth/presentation/pages/login_page.dart';
import 'package:patrol/patrol.dart';

/// 购物车服务端化之后的游客 E2E。
///
/// 购物车数据依赖 spring-shop 的登录态：游客点击「加入购物车」
/// 会被引导到登录页，加购、下单闭环需要已登录账号才能走通，
/// 属于后续登录态 E2E 的覆盖范围，这里只守住游客链路本身。
///
/// 注意：本用例依赖后端有商品数据（首页推荐流 / 商品详情），
/// 商品表为空时 /api/products 返回 500，用例会在推荐流加载处失败。
const Duration _quickSettle = Duration(seconds: 3);

/// 商品卡片的 InkWell 上带有 `home-product-card-<商品名>` 形态的 key。
/// 商品数据来自 spring-shop 后端接口，商品名编译期不可知，
/// 所以这里用谓词匹配所有商品卡片，而不是写死某个商品名。
Finder _productCardFinder() => find.byWidgetPredicate(
  (Widget widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('home-product-card-'),
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

void main() {
  patrolTest('游客从首页浏览商品、点详情加购后被引导到登录页', ($) async {
    await _launchApp($);

    // ---------- 首页 -> 商品详情 ----------
    // 推荐商品来自 spring-shop 后端接口，scrollUntilVisible 内部会
    // 先等卡片可点击（已可见则不滚动），不可见则逐段滚动直到可点击。
    final card = await $.scrollUntilVisible(
      finder: _productCardFinder(),
      delta: 150,
      settleBetweenScrollsTimeout: _quickSettle,
    );
    await card.tap(settleTimeout: _quickSettle);

    // ---------- 详情页点击加购 ----------
    // 游客没有服务端购物车，MainTabPage 会跳转登录页；
    // 详情页保留在栈里，登录返回后可再次加购。
    await $(const ValueKey<String>('product-detail-add-to-cart')).tap(
      settleTimeout: _quickSettle,
    );

    expect($(LoginPage), findsOneWidget);
  });
}
