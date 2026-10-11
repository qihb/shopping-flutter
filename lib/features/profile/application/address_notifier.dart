import 'package:flutter/foundation.dart';

import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/profile/data/address_service.dart';
import 'package:my_first_app/features/profile/data/models/address_vo.dart';

/// 收货地址状态管理（服务端化版本）。
///
/// 与购物车 [CartNotifier] 的编排方式一致：
/// - 数据源是 spring-shop 的 `/api/addresses` 系列接口，增删改查都走服务端
/// - 登录态变化（[AuthNotifier]）自动联动：登录后拉取、退出后清空
/// - 变更接口只返回成功与否，每次变更后重新拉取地址列表
class AddressNotifier extends ChangeNotifier {
  final AddressService _addressService;

  /// 关联的登录态，用于监听登录 / 退出并联动地址数据。
  AuthNotifier? _authNotifier;

  List<AddressVO> _addresses = const <AddressVO>[];
  bool _isLoading = false;
  String? _errorMessage;

  AddressNotifier({required this._addressService});

  /// 当前地址列表（不可变视图，默认地址在前）。
  List<AddressVO> get addresses => _addresses;

  /// 默认地址；没有地址时为 null。
  ///
  /// 服务端保证默认地址排在首位，这里仍按 isDefault 精确匹配，
  /// 找不到时回退到第一条，兼容旧数据顺序异常的情况。
  AddressVO? get defaultAddress {
    if (_addresses.isEmpty) {
      return null;
    }
    return _addresses.firstWhere(
      (AddressVO address) => address.isDefault,
      orElse: () => _addresses.first,
    );
  }

  /// 是否正在整页加载。
  bool get isLoading => _isLoading;

  /// 最近一次操作的错误提示；操作失败时由页面读取并弹出 SnackBar。
  String? get errorMessage => _errorMessage;

  // ---------- 登录态联动 ----------

  /// 关联登录态并自动联动：
  /// - 进入已登录 → 拉取服务端地址列表
  /// - 进入未登录 → 清空本地地址数据
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
    _addresses = const <AddressVO>[];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ---------- 读取 ----------

  /// 从服务端拉取地址列表。
  ///
  /// [showLoading] 为 true 时整页展示加载态（登录后首次拉取 / 重试）；
  /// 变更后的静默刷新传 false，避免列表闪烁。
  Future<void> refresh({bool showLoading = true}) async {
    // 地址接口需要登录，未登录时直接清空本地数据，不发无效请求。
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
      final List<AddressVO> fetchedAddresses =
          await _addressService.fetchAddresses();
      _addresses = fetchedAddresses;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _readableError(e, fallback: '地址加载失败，请稍后重试');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------- 变更 ----------

  /// 新增地址。
  Future<bool> addAddress({
    required String receiverName,
    required String receiverPhone,
    required String province,
    required String city,
    required String district,
    required String detailAddress,
    bool isDefault = false,
  }) {
    return _mutate(
      () => _addressService.addAddress(
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        province: province,
        city: city,
        district: district,
        detailAddress: detailAddress,
        isDefault: isDefault,
      ),
      fallbackMessage: '保存地址失败，请稍后重试',
    );
  }

  /// 修改地址。
  Future<bool> updateAddress({
    required int id,
    required String receiverName,
    required String receiverPhone,
    required String province,
    required String city,
    required String district,
    required String detailAddress,
    bool isDefault = false,
  }) {
    return _mutate(
      () => _addressService.updateAddress(
        id: id,
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        province: province,
        city: city,
        district: district,
        detailAddress: detailAddress,
        isDefault: isDefault,
      ),
      fallbackMessage: '保存地址失败，请稍后重试',
    );
  }

  /// 删除单条地址。
  Future<bool> deleteAddress(int id) {
    return _mutate(
      () => _addressService.deleteAddress(id),
      fallbackMessage: '删除地址失败，请稍后重试',
    );
  }

  /// 设为默认地址。
  Future<bool> setDefaultAddress(int id) {
    return _mutate(
      () => _addressService.setDefaultAddress(id),
      fallbackMessage: '设置默认地址失败，请稍后重试',
    );
  }

  /// 执行一次服务端变更，成功后静默刷新地址列表。
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
