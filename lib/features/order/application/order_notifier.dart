import 'package:flutter/foundation.dart';

import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/order/data/models/order_vo.dart';
import 'package:my_first_app/features/order/data/order_service.dart';
import 'package:my_first_app/features/payment/application/payment_service.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';

/// 订单状态管理（服务端化版本）。
///
/// 与购物车 [CartNotifier]、地址 `AddressNotifier` 的编排方式一致：
/// - 数据源是 spring-shop 的 `/api/orders` 系列接口，下单与状态流转都走服务端
/// - 支付动作委托给 [PaymentService]（当前为服务端模拟支付网关）
/// - 登录态变化（[AuthNotifier]）自动联动：登录后拉取、退出后清空
/// - 变更接口只返回成功与否，每次变更后重新拉取订单列表
class OrderNotifier extends ChangeNotifier {
  final OrderService _orderService;
  final PaymentService _paymentService;

  /// 关联的登录态，用于监听登录 / 退出并联动订单数据。
  AuthNotifier? _authNotifier;

  List<OrderVO> _orders = const <OrderVO>[];
  bool _isLoading = false;
  String? _errorMessage;

  OrderNotifier({
    required this._orderService,
    required this._paymentService,
  });

  /// 订单列表（不可变视图，服务端按下单时间倒序）。
  List<OrderVO> get orders => _orders;

  /// 是否正在整页加载。
  bool get isLoading => _isLoading;

  /// 最近一次操作的错误提示；操作失败时由页面读取并弹出 SnackBar。
  String? get errorMessage => _errorMessage;

  // ---------- 登录态联动 ----------

  /// 关联登录态并自动联动：
  /// - 进入已登录 → 拉取服务端订单列表
  /// - 进入未登录 → 清空本地订单数据
  ///
  /// 无论登录发生在哪个页面（登录页 / 个人中心），都通过监听
  /// [AuthNotifier] 自动触发，页面不需要手动编排。
  void attachAuth(AuthNotifier authNotifier) {
    _authNotifier?.removeListener(_onAuthChanged);
    _authNotifier = authNotifier;
    _authNotifier!.addListener(_onAuthChanged);

    // attach 时登录态可能已经确定（如测试先构造好登录态），立即对齐一次。
    _syncWithAuthStatus();
  }

  @override
  void dispose() {
    _authNotifier?.removeListener(_onAuthChanged);
    _authNotifier = null;
    super.dispose();
  }

  void _onAuthChanged() {
    _syncWithAuthStatus();
  }

  void _syncWithAuthStatus() {
    final AuthNotifier? auth = _authNotifier;

    if (auth == null) {
      return;
    }

    switch (auth.status) {
      case AuthStatus.authenticated:
        refresh();
      case AuthStatus.unauthenticated:
        _resetLocalState();
      case AuthStatus.restoring:
        // 会话恢复中不动作，等恢复结果出来后再联动。
        break;
    }
  }

  void _resetLocalState() {
    _orders = const <OrderVO>[];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ---------- 读取 ----------

  /// 从服务端拉取订单列表。
  ///
  /// [showLoading] 为 true 时整页展示加载态（登录后首次拉取 / 重试）；
  /// 变更后的静默刷新传 false，避免列表闪烁。
  Future<void> refresh({bool showLoading = true}) async {
    // 订单接口需要登录，未登录时直接清空本地数据，不发无效请求。
    final bool isLoggedIn = _authNotifier?.isAuthenticated ?? true;

    if (!isLoggedIn) {
      _resetLocalState();
      return;
    }

    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final List<OrderVO> fetchedOrders = await _orderService.fetchOrders();
      _orders = fetchedOrders;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _readableError(e, fallback: '订单加载失败，请稍后重试');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------- 变更 ----------

  /// 创建订单（来源固定为购物车勾选项），成功后静默刷新列表。
  ///
  /// 返回服务端生成的订单号，供随后的支付动作定位订单；
  /// 失败时返回 null 并把可读错误写入 [errorMessage]。
  Future<String?> createOrder({required int addressId, String? remark}) async {
    String orderNo;

    try {
      orderNo = await _orderService.createOrder(
        addressId: addressId,
        remark: remark,
      );
    } catch (e) {
      _errorMessage = _readableError(e, fallback: '创建订单失败，请稍后重试');
      notifyListeners();
      return null;
    }

    await refresh(showLoading: false);
    return orderNo;
  }

  /// 支付订单（服务端模拟网关），成功后静默刷新列表。
  ///
  /// 返回 true 表示支付成功；失败时把可读错误写入 [errorMessage]。
  /// [method] 当前仅透传到支付结果模型供 UI 展示，模拟网关不区分渠道。
  Future<bool> payOrder(
    String orderNo, {
    PaymentMethod method = PaymentMethod.alipay,
  }) async {
    try {
      final PaymentResult result = await _paymentService.pay(
        PaymentRequest(orderId: orderNo, method: method),
      );

      if (result.status != PaymentStatus.success) {
        _errorMessage = result.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _readableError(e, fallback: '支付失败，请稍后重试');
      notifyListeners();
      return false;
    }

    await refresh(showLoading: false);
    return true;
  }

  /// 确认收货：待收货 → 已完成。
  Future<bool> confirmReceipt(String orderNo) {
    return _mutate(
      () => _orderService.confirmReceipt(orderNo),
      fallbackMessage: '确认收货失败，请稍后重试',
    );
  }

  /// 取消订单：待付款 → 已取消（服务端回滚库存）。
  Future<bool> cancelOrder(String orderNo) {
    return _mutate(
      () => _orderService.cancelOrder(orderNo),
      fallbackMessage: '取消订单失败，请稍后重试',
    );
  }

  /// 执行一次服务端变更，成功后静默刷新订单列表。
  ///
  /// 返回 true 表示变更成功；失败时把可读错误写入 [errorMessage]
  /// 并返回 false，由调用方决定如何提示。
  Future<bool> _mutate(
    Future<void> Function() action, {
    required String fallbackMessage,
  }) async {
    try {
      await action();
    } catch (e) {
      _errorMessage = _readableError(e, fallback: fallbackMessage);
      notifyListeners();
      return false;
    }

    await refresh(showLoading: false);
    return true;
  }

  /// 把异常转换成用户能看懂的提示，与 [CartNotifier] 的策略一致。
  String _readableError(Object error, {required String fallback}) {
    if (error is ApiException) {
      return error.message;
    }

    return fallback;
  }
}
