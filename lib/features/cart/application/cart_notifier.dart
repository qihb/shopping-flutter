import 'package:flutter/foundation.dart';

import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/cart/data/cart_service.dart';
import 'package:my_first_app/features/cart/data/models/cart_item_vo.dart';
import 'package:my_first_app/features/cart/data/models/cart_vo.dart';

/// 购物车状态管理（服务端化版本）。
///
/// 与旧版本地购物车的区别：
/// - 数据源是 spring-shop 的 `/api/cart` 系列接口，所有操作都走服务端
/// - 登录态变化（[AuthNotifier]）自动联动：登录后拉取、退出后清空
/// - 变更接口只返回成功与否，每次变更后重新拉取购物车刷新列表与汇总
///
/// 依旧沿用项目约定的 `ChangeNotifier` + `provider` 方案：
/// 页面通过 `context.watch<CartNotifier>()` 重建，
/// 通过 `context.read<CartNotifier>()` 触发操作。
class CartNotifier extends ChangeNotifier {
  final CartService _cartService;

  /// 关联的登录态，用于监听登录 / 退出并联动购物车数据。
  AuthNotifier? _authNotifier;

  CartVO? _cart;
  bool _isLoading = false;
  String? _errorMessage;

  CartNotifier({required this._cartService});

  /// 当前购物车数据，未登录或未加载时为 null。
  CartVO? get cart => _cart;

  /// 购物车条目列表（不可变视图）。
  List<CartItemVO> get items => _cart?.items ?? const <CartItemVO>[];

  /// 购物车总件数（含未勾选与失效条目），底部导航角标用它。
  int get totalQuantity => _cart?.totalQuantity ?? 0;

  /// 已勾选件数（仅有效条目）。
  int get checkedQuantity => _cart?.checkedQuantity ?? 0;

  /// 已勾选金额合计（仅有效条目），由服务端计算。
  double get checkedAmount => _cart?.checkedAmount ?? 0;

  /// 是否正在整页加载。
  bool get isLoading => _isLoading;

  /// 最近一次操作的错误提示；操作失败时由页面读取并弹出 SnackBar。
  String? get errorMessage => _errorMessage;

  /// 是否没有任何条目。
  bool get isEmpty => _cart == null || _cart!.items.isEmpty;

  /// 已勾选且有效的条目，即「去结算」时的下单范围。
  ///
  /// 订单确认页与下单编排都以这份服务端条目为准，
  /// 失效条目与未勾选条目不参与结算。
  List<CartItemVO> get selectedItems {
    final CartVO? currentCart = _cart;

    if (currentCart == null) {
      return const <CartItemVO>[];
    }

    return currentCart.items
        .where((CartItemVO item) => item.checked && !item.invalid)
        .toList(growable: false);
  }

  // ---------- 登录态联动 ----------

  /// 关联登录态并自动联动：
  /// - 进入已登录 → 拉取服务端购物车
  /// - 进入未登录 → 清空本地购物车数据
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
    _cart = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ---------- 读取 ----------

  /// 从服务端拉取购物车列表与汇总。
  ///
  /// [showLoading] 为 true 时整页展示加载态（进入页面 / 重试）；
  /// 变更后的静默刷新传 false，避免列表闪烁。
  Future<void> refresh({bool showLoading = true}) async {
    // 购物车接口需要登录，未登录时直接清空本地数据，不发无效请求。
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
      final CartVO fetchedCart = await _cartService.fetchCart();
      _cart = fetchedCart;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _readableError(e, fallback: '购物车加载失败，请稍后重试');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------- 变更 ----------

  /// 加入购物车（SKU 维度）。
  Future<bool> addToCart({required int skuId, int quantity = 1}) {
    return _mutate(
      () => _cartService.addItem(skuId: skuId, quantity: quantity),
      fallbackMessage: '加入购物车失败，请稍后重试',
    );
  }

  /// 修改条目购买数量。
  Future<bool> updateQuantity({
    required int itemId,
    required int quantity,
  }) {
    return _mutate(
      () => _cartService.updateQuantity(itemId: itemId, quantity: quantity),
      fallbackMessage: '修改数量失败，请稍后重试',
    );
  }

  /// 删除单条。
  Future<bool> removeItem(int itemId) {
    return _mutate(
      () => _cartService.removeItem(itemId),
      fallbackMessage: '删除商品失败，请稍后重试',
    );
  }

  /// 单条勾选 / 取消勾选。
  Future<bool> setItemChecked({
    required int itemId,
    required bool checked,
  }) {
    return _mutate(
      () => _cartService.setItemChecked(itemId: itemId, checked: checked),
      fallbackMessage: '操作失败，请稍后重试',
    );
  }

  /// 全选 / 全不选。
  Future<bool> setAllChecked({required bool checked}) {
    return _mutate(
      () => _cartService.setAllChecked(checked: checked),
      fallbackMessage: '操作失败，请稍后重试',
    );
  }

  /// 删除已勾选条目（下单成功后清理购物车）。
  Future<bool> removeCheckedItems() {
    return _mutate(
      _cartService.removeCheckedItems,
      fallbackMessage: '清理购物车失败，请稍后重试',
    );
  }

  /// 清空购物车。
  Future<bool> clearCart() {
    return _mutate(_cartService.clearCart, fallbackMessage: '清空购物车失败，请稍后重试');
  }

  /// 执行一次服务端变更，成功后静默刷新购物车。
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

  /// 把异常转换成用户能看懂的提示，与 [AuthNotifier] 的策略一致。
  String _readableError(Object error, {required String fallback}) {
    if (error is ApiException) {
      return error.message;
    }

    return fallback;
  }
}
