import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/auth/data/models/user_info.dart';
import 'package:my_first_app/features/cart/application/cart_notifier.dart';
import 'package:my_first_app/features/cart/data/models/cart_item_vo.dart';
import 'package:my_first_app/features/cart/data/models/cart_vo.dart';
import 'package:my_first_app/features/cart/presentation/pages/cart_page.dart';
import '../../../../helpers/mocks.mocks.dart';
import '../../../../helpers/stub_helpers.dart';

void main() {
  /// 构造未登录的登录态。
  AuthNotifier buildGuestAuth() {
    final MockAuthService authService = MockAuthService();
    final MockTokenStore tokenStore = MockTokenStore();
    when(tokenStore.readToken()).thenAnswer((_) async => null);

    return AuthNotifier(
      authService: authService,
      tokenStore: tokenStore,
    )..restoreSession();
  }

  /// 构造已登录的登录态（本地 token 有效）。
  AuthNotifier buildLoggedInAuth() {
    final MockAuthService authService = MockAuthService();
    final MockTokenStore tokenStore = MockTokenStore();
    when(tokenStore.readToken()).thenAnswer((_) async => 'test-token');
    when(authService.fetchCurrentUser()).thenAnswer(
      (_) async => const UserInfo(
        id: 1,
        username: 'tester',
        nickname: '测试用户',
        phone: '13800000000',
      ),
    );

    return AuthNotifier(
      authService: authService,
      tokenStore: tokenStore,
    )..restoreSession();
  }

  Widget buildCartPage({
    required MockCartService cartService,
    required AuthNotifier authNotifier,
    VoidCallback? onOpenConfirmPage,
    VoidCallback? onLogin,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
        ChangeNotifierProvider<CartNotifier>(
          create: (_) => CartNotifier(
            cartService: cartService,
          )..attachAuth(authNotifier),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CartPage(
            onOpenConfirmPage: onOpenConfirmPage,
            onLogin: onLogin,
          ),
        ),
      ),
    );
  }

  testWidgets('未登录时展示登录引导空态，去登录触发回调且不发请求', (WidgetTester tester) async {
    final AuthNotifier authNotifier = buildGuestAuth();
    final MockCartService cartService = MockCartService();
    bool didTapLogin = false;

    await tester.pumpWidget(buildCartPage(
      cartService: cartService,
      authNotifier: authNotifier,
      onLogin: () => didTapLogin = true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('登录后查看购物车'), findsOneWidget);
    expect(find.text('登录后即可同步你的购物车商品'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('cart-login-guide')));
    await tester.pump();

    expect(didTapLogin, isTrue);
    verifyNever(cartService.fetchCart());
  });

  testWidgets('已登录首次进入时展示整页加载态', (WidgetTester tester) async {
    final AuthNotifier authNotifier = buildLoggedInAuth();
    final MockCartService cartService = MockCartService();
    // fetchCart 永不完成，用于观察加载态。
    when(cartService.fetchCart())
        .thenAnswer((_) => Completer<CartVO>().future);

    await tester.pumpWidget(buildCartPage(
      cartService: cartService,
      authNotifier: authNotifier,
    ));
    await tester.pump();

    expect(find.text('购物车加载中...'), findsOneWidget);
  });

  testWidgets('已登录时渲染服务端条目与汇总，失效条目置灰禁操作', (WidgetTester tester) async {
    final AuthNotifier authNotifier = buildLoggedInAuth();
    final MockCartService cartService = MockCartService();
    stubCartFetch(
      cartService,
      buildTestCart(<CartItemVO>[
        buildTestCartItem(1, '夏季轻运动鞋', specs: '白色 / 42 码', quantity: 2),
        buildTestCartItem(
          2,
          '下架商品',
          checked: false,
          invalid: true,
          invalidReason: '商品已下架',
        ),
      ]),
    );

    await tester.pumpWidget(buildCartPage(
      cartService: cartService,
      authNotifier: authNotifier,
    ));
    await tester.pumpAndSettle();

    // 条目内容：名称 / 规格 / 单价。
    expect(find.text('夏季轻运动鞋'), findsOneWidget);
    expect(find.text('白色 / 42 码'), findsOneWidget);
    expect(find.text('¥89'), findsOneWidget);

    // 失效条目：展示失效原因，不展示价格，也没有数量步进器。
    expect(find.text('下架商品'), findsOneWidget);
    expect(find.text('商品已下架'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('cart-decrease-2')), findsNothing);
    expect(find.byKey(const ValueKey<String>('cart-increase-2')), findsNothing);

    // 头部与结算区汇总来自服务端口径：总件数含失效条目。
    expect(find.text('购物车共 3 件'), findsOneWidget);
    expect(find.text('合计 ¥178'), findsOneWidget);
    expect(find.text('已勾选 2 件'), findsOneWidget);
  });

  testWidgets('条目勾选、全选、数量步进、删除、清空都走服务端接口', (WidgetTester tester) async {
    final AuthNotifier authNotifier = buildLoggedInAuth();
    final MockCartService cartService = MockCartService();
    stubCartMutationsSuccess(cartService);
    stubCartFetch(
      cartService,
      buildTestCart(<CartItemVO>[
        buildTestCartItem(1, '夏季轻运动鞋', quantity: 2),
        buildTestCartItem(2, '极简双肩包', price: 129, checked: false),
      ]),
    );

    await tester.pumpWidget(buildCartPage(
      cartService: cartService,
      authNotifier: authNotifier,
    ));
    await tester.pumpAndSettle();

    // 单条取消勾选。
    await tester.tap(find.byKey(const ValueKey<String>('cart-check-1')));
    await tester.pumpAndSettle();
    verify(cartService.setItemChecked(itemId: 1, checked: false)).called(1);

    // 全选（当前存在未勾选条目，点击后应发起全选）。
    await tester.tap(find.byKey(const ValueKey<String>('cart-check-all')));
    await tester.pumpAndSettle();
    verify(cartService.setAllChecked(checked: true)).called(1);

    // 增加数量。
    await tester.tap(find.byKey(const ValueKey<String>('cart-increase-1')));
    await tester.pumpAndSettle();
    verify(cartService.updateQuantity(itemId: 1, quantity: 3)).called(1);

    // 减少数量（数量为 2，可以减）。
    await tester.tap(find.byKey(const ValueKey<String>('cart-decrease-1')));
    await tester.pumpAndSettle();
    verify(cartService.updateQuantity(itemId: 1, quantity: 1)).called(1);

    // 删除单条。
    await tester.tap(find.byKey(const ValueKey<String>('cart-delete-2')));
    await tester.pumpAndSettle();
    verify(cartService.removeItem(2)).called(1);

    // 清空购物车。
    await tester.tap(find.byKey(const ValueKey<String>('cart-clear-all')));
    await tester.pumpAndSettle();
    verify(cartService.clearCart()).called(1);
  });

  testWidgets('没有可结算条目时提交订单按钮禁用', (WidgetTester tester) async {
    final AuthNotifier authNotifier = buildLoggedInAuth();
    final MockCartService cartService = MockCartService();
    bool didOpenConfirmPage = false;
    stubCartFetch(
      cartService,
      buildTestCart(<CartItemVO>[
        buildTestCartItem(1, '夏季轻运动鞋', checked: false),
      ]),
    );

    await tester.pumpWidget(buildCartPage(
      cartService: cartService,
      authNotifier: authNotifier,
      onOpenConfirmPage: () => didOpenConfirmPage = true,
    ));
    await tester.pumpAndSettle();

    final FilledButton submitButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey<String>('cart-submit-order')),
    );
    expect(submitButton.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey<String>('cart-submit-order')));
    await tester.pump();

    expect(didOpenConfirmPage, isFalse);
  });

  testWidgets('已勾选时点击提交订单触发回调', (WidgetTester tester) async {
    final AuthNotifier authNotifier = buildLoggedInAuth();
    final MockCartService cartService = MockCartService();
    bool didOpenConfirmPage = false;
    stubCartFetch(cartService, buildDefaultTestCart());

    await tester.pumpWidget(buildCartPage(
      cartService: cartService,
      authNotifier: authNotifier,
      onOpenConfirmPage: () => didOpenConfirmPage = true,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('cart-submit-order')));
    await tester.pump();

    expect(didOpenConfirmPage, isTrue);
  });

  testWidgets('操作失败时弹出服务端错误提示', (WidgetTester tester) async {
    final AuthNotifier authNotifier = buildLoggedInAuth();
    final MockCartService cartService = MockCartService();
    stubCartMutationsSuccess(cartService);
    stubCartFetch(cartService, buildDefaultTestCart());
    when(cartService.updateQuantity(
      itemId: anyNamed('itemId'),
      quantity: anyNamed('quantity'),
    )).thenThrow(ApiException(message: '库存不足'));

    await tester.pumpWidget(buildCartPage(
      cartService: cartService,
      authNotifier: authNotifier,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('cart-increase-1')));
    await tester.pumpAndSettle();

    expect(find.text('库存不足'), findsOneWidget);

    // 让 SnackBar 的自动消失计时器走完，避免测试结束时残留 Timer。
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('已登录但购物车为空时展示空购物车文案', (WidgetTester tester) async {
    final AuthNotifier authNotifier = buildLoggedInAuth();
    final MockCartService cartService = MockCartService();
    stubCartFetch(cartService, buildTestCart(const <CartItemVO>[]));

    await tester.pumpWidget(buildCartPage(
      cartService: cartService,
      authNotifier: authNotifier,
    ));
    await tester.pumpAndSettle();

    expect(find.text('购物车还是空的'), findsOneWidget);
    expect(find.text('先去首页挑一件喜欢的商品吧'), findsOneWidget);
  });
}
