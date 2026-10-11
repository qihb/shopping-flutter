import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/auth/data/models/user_info.dart';
import 'package:my_first_app/features/order/application/order_notifier.dart';
import 'package:my_first_app/features/order/data/models/order_status.dart';
import 'package:my_first_app/features/order/data/models/order_vo.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';
import '../../../helpers/mocks.mocks.dart';
import '../../../helpers/stub_helpers.dart';

/// 一次订单状态测试的完整替身集合。
typedef _OrderFixture = (
  AuthNotifier authNotifier,
  MockAuthService authService,
  OrderNotifier orderNotifier,
  MockOrderService orderService,
  MockPaymentService paymentService,
);

void main() {
  /// 组装订单状态并与登录态关联。
  _OrderFixture buildFixture(
    MockAuthService authService,
    AuthNotifier authNotifier,
  ) {
    final MockOrderService orderService = MockOrderService();
    final MockPaymentService paymentService = MockPaymentService();
    final OrderNotifier orderNotifier = OrderNotifier(
      orderService: orderService,
      paymentService: paymentService,
    )..attachAuth(authNotifier);

    return (
      authNotifier,
      authService,
      orderNotifier,
      orderService,
      paymentService,
    );
  }

  /// 构造未登录的登录态（本地无 token）。
  _OrderFixture buildGuestFixture() {
    final MockAuthService authService = MockAuthService();
    final MockTokenStore tokenStore = MockTokenStore();
    when(tokenStore.readToken()).thenAnswer((_) async => null);

    final AuthNotifier authNotifier = AuthNotifier(
      authService: authService,
      tokenStore: tokenStore,
    );
    return buildFixture(authService, authNotifier);
  }

  /// 构造已登录的登录态（本地 token 有效）。
  _OrderFixture buildLoggedInFixture() {
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
    return buildFixture(authService, authNotifier);
  }

  /// 让登录联动触发的异步刷新跑完（纯微任务链，让出一轮事件循环即可）。
  Future<void> flushAsync() => Future<void>.delayed(Duration.zero);

  group('登录态联动', () {
    test('未登录时不会拉取订单', () async {
      final (
        AuthNotifier authNotifier,
        MockAuthService _,
        OrderNotifier orderNotifier,
        MockOrderService orderService,
        MockPaymentService _,
      ) = buildGuestFixture();

      await authNotifier.restoreSession();
      await flushAsync();

      verifyNever(orderService.fetchOrders(current: anyNamed('current')));
      expect(orderNotifier.orders, isEmpty);
    });

    test('会话恢复成功后自动拉取服务端订单', () async {
      final (
        AuthNotifier authNotifier,
        MockAuthService _,
        OrderNotifier orderNotifier,
        MockOrderService orderService,
        MockPaymentService _,
      ) = buildLoggedInFixture();
      stubOrderFetch(
        orderService,
        <OrderVO>[buildTestOrderVO(1, 'ORD-0000001')],
      );

      await authNotifier.restoreSession();
      await flushAsync();

      verify(orderService.fetchOrders(current: anyNamed('current'))).called(1);
      expect(orderNotifier.orders, hasLength(1));
      expect(orderNotifier.orders.first.orderNo, 'ORD-0000001');
      expect(orderNotifier.orders.first.statusLabel, '待发货');
    });

    test('登录成功后自动拉取服务端订单', () async {
      final (
        AuthNotifier authNotifier,
        MockAuthService authService,
        OrderNotifier orderNotifier,
        MockOrderService orderService,
        MockPaymentService _,
      ) = buildLoggedInFixture();
      stubOrderFetch(
        orderService,
        <OrderVO>[buildTestOrderVO(1, 'ORD-0000001')],
      );
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
      verify(orderService.fetchOrders(current: anyNamed('current'))).called(1);
      expect(orderNotifier.orders, hasLength(1));
    });

    test('退出登录后清空本地订单数据', () async {
      final (
        AuthNotifier authNotifier,
        MockAuthService authService,
        OrderNotifier orderNotifier,
        MockOrderService orderService,
        MockPaymentService _,
      ) = buildLoggedInFixture();
      stubOrderFetch(
        orderService,
        <OrderVO>[buildTestOrderVO(1, 'ORD-0000001')],
      );
      when(authService.logout()).thenAnswer((_) async {});

      await authNotifier.restoreSession();
      await flushAsync();
      expect(orderNotifier.orders, hasLength(1));

      await authNotifier.logout();
      await flushAsync();

      expect(orderNotifier.orders, isEmpty);
      expect(orderNotifier.errorMessage, isNull);
    });
  });

  group('读取与错误处理', () {
    test('刷新成功后订单列表来自服务端', () async {
      final MockOrderService orderService = MockOrderService();
      final MockPaymentService paymentService = MockPaymentService();
      final OrderNotifier orderNotifier = OrderNotifier(
        orderService: orderService,
        paymentService: paymentService,
      );
      stubOrderFetch(
        orderService,
        <OrderVO>[
          buildTestOrderVO(1, 'ORD-0000001'),
          buildTestOrderVO(2, 'ORD-0000002', status: OrderStatus.pendingPayment),
        ],
      );

      await orderNotifier.refresh();

      expect(orderNotifier.isLoading, isFalse);
      expect(orderNotifier.errorMessage, isNull);
      expect(orderNotifier.orders, hasLength(2));
      expect(orderNotifier.orders.last.canPay, isTrue);
    });

    test('刷新失败时记录错误信息并结束加载态', () async {
      final MockOrderService orderService = MockOrderService();
      final MockPaymentService paymentService = MockPaymentService();
      final OrderNotifier orderNotifier = OrderNotifier(
        orderService: orderService,
        paymentService: paymentService,
      );
      when(orderService.fetchOrders(current: anyNamed('current')))
          .thenThrow(ApiException(message: '登录已过期'));

      await orderNotifier.refresh();

      expect(orderNotifier.errorMessage, '登录已过期');
      expect(orderNotifier.isLoading, isFalse);
    });
  });

  group('下单与支付', () {
    test('下单成功后返回订单号并静默刷新列表', () async {
      final MockOrderService orderService = MockOrderService();
      final MockPaymentService paymentService = MockPaymentService();
      final OrderNotifier orderNotifier = OrderNotifier(
        orderService: orderService,
        paymentService: paymentService,
      );
      stubOrderMutationsSuccess(orderService);
      stubOrderFetch(
        orderService,
        <OrderVO>[
          buildTestOrderVO(1, 'ORD-0000001', status: OrderStatus.pendingPayment),
        ],
      );

      final String? orderNo =
          await orderNotifier.createOrder(addressId: 5, remark: '尽快发货');

      expect(orderNo, 'ORD-0000001');
      verify(orderService.createOrder(addressId: 5, remark: '尽快发货'))
          .called(1);
      // 变更后的静默刷新不展示加载态，但列表会重新拉取。
      verify(orderService.fetchOrders(current: anyNamed('current'))).called(1);
      expect(orderNotifier.orders, hasLength(1));
      expect(orderNotifier.errorMessage, isNull);
    });

    test('下单失败时返回 null 并记录错误信息', () async {
      final MockOrderService orderService = MockOrderService();
      final MockPaymentService paymentService = MockPaymentService();
      final OrderNotifier orderNotifier = OrderNotifier(
        orderService: orderService,
        paymentService: paymentService,
      );
      when(orderService.createOrder(
        addressId: anyNamed('addressId'),
        remark: anyNamed('remark'),
      )).thenThrow(ApiException(message: '库存不足'));

      final String? orderNo =
          await orderNotifier.createOrder(addressId: 5, remark: null);

      expect(orderNo, isNull);
      expect(orderNotifier.errorMessage, '库存不足');
      // 下单失败后不会触发列表刷新。
      verifyNever(orderService.fetchOrders(current: anyNamed('current')));
    });

    test('支付成功后返回 true 并静默刷新列表', () async {
      final MockOrderService orderService = MockOrderService();
      final MockPaymentService paymentService = MockPaymentService();
      final OrderNotifier orderNotifier = OrderNotifier(
        orderService: orderService,
        paymentService: paymentService,
      );
      stubOrderFetch(
        orderService,
        <OrderVO>[
          buildTestOrderVO(1, 'ORD-0000001', status: OrderStatus.pendingShipment),
        ],
      );
      when(paymentService.pay(any)).thenAnswer(
        (_) async => const PaymentResult(
          method: PaymentMethod.alipay,
          status: PaymentStatus.success,
          message: '支付成功',
        ),
      );

      final bool didSucceed = await orderNotifier.payOrder('ORD-0000001');

      expect(didSucceed, isTrue);
      expect(orderNotifier.errorMessage, isNull);

      // 支付请求指向下单返回的订单号，渠道沿用默认收银台选择。
      final PaymentRequest request =
          verify(paymentService.pay(captureAny)).captured.single
              as PaymentRequest;
      expect(request.orderId, 'ORD-0000001');
      expect(request.method, PaymentMethod.alipay);

      verify(orderService.fetchOrders(current: anyNamed('current'))).called(1);
    });

    test('网关返回失败结果时透传提示并不刷新列表', () async {
      final MockOrderService orderService = MockOrderService();
      final MockPaymentService paymentService = MockPaymentService();
      final OrderNotifier orderNotifier = OrderNotifier(
        orderService: orderService,
        paymentService: paymentService,
      );
      when(paymentService.pay(any)).thenAnswer(
        (_) async => const PaymentResult(
          method: PaymentMethod.alipay,
          status: PaymentStatus.failure,
          message: '订单状态不支持支付',
        ),
      );

      final bool didSucceed = await orderNotifier.payOrder('ORD-0000001');

      expect(didSucceed, isFalse);
      expect(orderNotifier.errorMessage, '订单状态不支持支付');
      verifyNever(orderService.fetchOrders(current: anyNamed('current')));
    });

    test('支付抛出非业务异常时收敛为兜底提示', () async {
      final MockOrderService orderService = MockOrderService();
      final MockPaymentService paymentService = MockPaymentService();
      final OrderNotifier orderNotifier = OrderNotifier(
        orderService: orderService,
        paymentService: paymentService,
      );
      when(paymentService.pay(any)).thenThrow(Exception('connection reset'));

      final bool didSucceed = await orderNotifier.payOrder('ORD-0000001');

      expect(didSucceed, isFalse);
      expect(orderNotifier.errorMessage, '支付失败，请稍后重试');
    });
  });

  group('订单状态流转', () {
    test('确认收货 / 取消订单分别调用对应接口并静默刷新', () async {
      final MockOrderService orderService = MockOrderService();
      final MockPaymentService paymentService = MockPaymentService();
      final OrderNotifier orderNotifier = OrderNotifier(
        orderService: orderService,
        paymentService: paymentService,
      );
      stubOrderMutationsSuccess(orderService);
      stubOrderFetch(
        orderService,
        <OrderVO>[
          buildTestOrderVO(
            1,
            'ORD-0000001',
            status: OrderStatus.pendingDelivery,
          ),
        ],
      );

      final bool didConfirm = await orderNotifier.confirmReceipt('ORD-0000001');
      expect(didConfirm, isTrue);
      verify(orderService.confirmReceipt('ORD-0000001')).called(1);

      final bool didCancel = await orderNotifier.cancelOrder('ORD-0000002');
      expect(didCancel, isTrue);
      verify(orderService.cancelOrder('ORD-0000002')).called(1);

      // 两次变更各自触发一次静默刷新。
      verify(orderService.fetchOrders(current: anyNamed('current'))).called(2);
    });

    test('确认收货失败时返回 false 并记录错误信息', () async {
      final MockOrderService orderService = MockOrderService();
      final MockPaymentService paymentService = MockPaymentService();
      final OrderNotifier orderNotifier = OrderNotifier(
        orderService: orderService,
        paymentService: paymentService,
      );
      when(orderService.confirmReceipt(any))
          .thenThrow(ApiException(message: '订单状态已变化'));

      final bool didConfirm = await orderNotifier.confirmReceipt('ORD-0000001');

      expect(didConfirm, isFalse);
      expect(orderNotifier.errorMessage, '订单状态已变化');
      verifyNever(orderService.fetchOrders(current: anyNamed('current')));
    });
  });
}
