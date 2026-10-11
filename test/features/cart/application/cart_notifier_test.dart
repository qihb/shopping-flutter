import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/auth/data/models/user_info.dart';
import 'package:my_first_app/features/cart/application/cart_notifier.dart';
import 'package:my_first_app/features/cart/data/models/cart_item_vo.dart';
import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';
import '../../../helpers/mocks.mocks.dart';
import '../../../helpers/stub_helpers.dart';

void main() {
  /// 构造未登录的登录态（本地无 token）。
  (AuthNotifier, CartNotifier, MockCartService) buildGuestFixture() {
    final MockAuthService authService = MockAuthService();
    final MockTokenStore tokenStore = MockTokenStore();
    when(tokenStore.readToken()).thenAnswer((_) async => null);

    final AuthNotifier authNotifier = AuthNotifier(
      authService: authService,
      tokenStore: tokenStore,
    );
    final MockCartService cartService = MockCartService();
    final CartNotifier cartNotifier = CartNotifier(
      cartService: cartService,
    )..attachAuth(authNotifier);

    return (authNotifier, cartNotifier, cartService);
  }

  /// 构造已登录的登录态（本地 token 有效），并关联购物车。
  (AuthNotifier, CartNotifier, MockCartService, MockAuthService)
      buildLoggedInFixture() {
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

    final AuthNotifier authNotifier = AuthNotifier(
      authService: authService,
      tokenStore: tokenStore,
    );
    final MockCartService cartService = MockCartService();
    final CartNotifier cartNotifier = CartNotifier(
      cartService: cartService,
    )..attachAuth(authNotifier);

    return (authNotifier, cartNotifier, cartService, authService);
  }

  /// 让登录联动触发的异步刷新跑完（纯微任务链，让出一轮事件循环即可）。
  Future<void> flushAsync() => Future<void>.delayed(Duration.zero);

  group('登录态联动', () {
    test('未登录时不会拉取购物车', () async {
      final (
        AuthNotifier authNotifier,
        CartNotifier cartNotifier,
        MockCartService cartService,
      ) = buildGuestFixture();

      await authNotifier.restoreSession();
      await flushAsync();

      verifyNever(cartService.fetchCart());
      expect(cartNotifier.isEmpty, isTrue);
    });

    test('会话恢复成功后自动拉取服务端购物车', () async {
      final (
        AuthNotifier authNotifier,
        CartNotifier cartNotifier,
        MockCartService cartService,
        MockAuthService _,
      ) = buildLoggedInFixture();
      stubCartFetch(cartService, buildDefaultTestCart());

      await authNotifier.restoreSession();
      await flushAsync();

      verify(cartService.fetchCart()).called(1);
      expect(cartNotifier.items, hasLength(1));
      expect(cartNotifier.totalQuantity, 1);
      expect(cartNotifier.checkedAmount, 89);
    });

    test('登录成功后自动拉取服务端购物车', () async {
      final (
        AuthNotifier authNotifier,
        CartNotifier cartNotifier,
        MockCartService cartService,
        MockAuthService authService,
      ) = buildLoggedInFixture();
      stubCartFetch(cartService, buildDefaultTestCart());
      when(authService.login(
        username: anyNamed('username'),
        password: anyNamed('password'),
      )).thenAnswer(
        (_) async => const LoginResult(
          token: 'token-1',
          user: UserInfo(
            id: 1,
            username: 'tester',
            nickname: '测试用户',
            phone: '',
          ),
        ),
      );

      final bool didLogin =
          await authNotifier.login(username: 'tester', password: '123456');
      await flushAsync();

      expect(didLogin, isTrue);
      verify(cartService.fetchCart()).called(1);
      expect(cartNotifier.items, hasLength(1));
    });

    test('退出登录后清空本地购物车数据', () async {
      final (
        AuthNotifier authNotifier,
        CartNotifier cartNotifier,
        MockCartService cartService,
        MockAuthService authService,
      ) = buildLoggedInFixture();
      stubCartFetch(cartService, buildDefaultTestCart());
      when(authService.logout()).thenAnswer((_) async {});

      await authNotifier.restoreSession();
      await flushAsync();
      expect(cartNotifier.items, hasLength(1));

      await authNotifier.logout();
      await flushAsync();

      expect(cartNotifier.cart, isNull);
      expect(cartNotifier.isEmpty, isTrue);
    });
  });

  group('读取与错误处理', () {
    test('未登录时 refresh 不发请求', () async {
      final (
        AuthNotifier _,
        CartNotifier cartNotifier,
        MockCartService cartService,
      ) = buildGuestFixture();

      await cartNotifier.refresh();

      verifyNever(cartService.fetchCart());
      expect(cartNotifier.isEmpty, isTrue);
    });

    test('刷新成功后条目与汇总来自服务端', () async {
      final MockCartService cartService = MockCartService();
      final CartNotifier cartNotifier = CartNotifier(cartService: cartService);
      stubCartFetch(
        cartService,
        buildTestCart(<CartItemVO>[
          buildTestCartItem(1, '夏季轻运动鞋', quantity: 2),
        ]),
      );

      await cartNotifier.refresh();

      expect(cartNotifier.isLoading, isFalse);
      expect(cartNotifier.errorMessage, isNull);
      expect(cartNotifier.totalQuantity, 2);
      expect(cartNotifier.checkedQuantity, 2);
      expect(cartNotifier.checkedAmount, 178);
    });

    test('刷新失败时记录错误信息并结束加载态', () async {
      final MockCartService cartService = MockCartService();
      final CartNotifier cartNotifier = CartNotifier(cartService: cartService);
      when(cartService.fetchCart())
          .thenThrow(ApiException(message: '登录已过期'));

      await cartNotifier.refresh();

      expect(cartNotifier.errorMessage, '登录已过期');
      expect(cartNotifier.isLoading, isFalse);
    });
  });

  group('变更操作', () {
    test('加购成功后调用服务端并静默刷新', () async {
      final MockCartService cartService = MockCartService();
      final CartNotifier cartNotifier = CartNotifier(cartService: cartService);
      stubCartMutationsSuccess(cartService);
      stubCartFetch(cartService, buildDefaultTestCart());

      final bool didSucceed = await cartNotifier.addToCart(skuId: 9001);

      expect(didSucceed, isTrue);
      verify(cartService.addItem(skuId: 9001, quantity: 1)).called(1);
      verify(cartService.fetchCart()).called(1);
      expect(cartNotifier.items, hasLength(1));
    });

    test('加购失败时返回 false 并记录错误信息', () async {
      final MockCartService cartService = MockCartService();
      final CartNotifier cartNotifier = CartNotifier(cartService: cartService);
      when(cartService.addItem(
        skuId: anyNamed('skuId'),
        quantity: anyNamed('quantity'),
      )).thenThrow(ApiException(message: '库存不足'));

      final bool didSucceed = await cartNotifier.addToCart(skuId: 9001);

      expect(didSucceed, isFalse);
      expect(cartNotifier.errorMessage, '库存不足');
      expect(cartNotifier.isEmpty, isTrue);
    });

    test('改数量 / 勾选 / 全选 / 删除 / 清空 / 清已勾选分别调用对应接口', () async {
      final MockCartService cartService = MockCartService();
      final CartNotifier cartNotifier = CartNotifier(cartService: cartService);
      stubCartMutationsSuccess(cartService);
      stubCartFetch(cartService, buildDefaultTestCart());

      await cartNotifier.updateQuantity(itemId: 1, quantity: 3);
      verify(cartService.updateQuantity(itemId: 1, quantity: 3)).called(1);

      await cartNotifier.setItemChecked(itemId: 1, checked: false);
      verify(cartService.setItemChecked(itemId: 1, checked: false)).called(1);

      await cartNotifier.setAllChecked(checked: true);
      verify(cartService.setAllChecked(checked: true)).called(1);

      await cartNotifier.removeItem(1);
      verify(cartService.removeItem(1)).called(1);

      await cartNotifier.clearCart();
      verify(cartService.clearCart()).called(1);

      await cartNotifier.removeCheckedItems();
      verify(cartService.removeCheckedItems()).called(1);
    });
  });

  group('selectedItems 桥接', () {
    test('只保留已勾选且有效的条目，并映射成旧 CartItem 模型', () async {
      final MockCartService cartService = MockCartService();
      final CartNotifier cartNotifier = CartNotifier(cartService: cartService);
      stubCartFetch(
        cartService,
        buildTestCart(<CartItemVO>[
          buildTestCartItem(1, '已勾选商品', checked: true),
          buildTestCartItem(2, '未勾选商品', checked: false),
          buildTestCartItem(
            3,
            '失效商品',
            checked: true,
            invalid: true,
            invalidReason: '商品已下架',
          ),
        ]),
      );

      await cartNotifier.refresh();

      expect(cartNotifier.selectedItems, hasLength(1));
      final CartItem bridgeItem = cartNotifier.selectedItems.single;
      expect(bridgeItem.name, '已勾选商品');
      expect(bridgeItem.unitPrice, 89);
      expect(bridgeItem.priceLabel, '¥89');
      expect(bridgeItem.quantity, 1);
      expect(bridgeItem.totalPriceLabel, '¥89');
    });
  });
}
