import 'package:flutter/foundation.dart';

import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/data/auth_service.dart';
import 'package:my_first_app/features/auth/data/models/user_info.dart';
import 'package:my_first_app/features/auth/data/token_store.dart';

/// 登录态的三个阶段：
/// - [restoring]：冷启动时正在用本地 token 换取用户信息，UI 显示加载态
/// - [unauthenticated]：未登录
/// - [authenticated]：已登录，[user] 一定有值
enum AuthStatus { restoring, unauthenticated, authenticated }

/// 登录态状态管理。
///
/// 项目当前复杂度下沿用项目约定的 `ChangeNotifier` + `provider` 方案：
/// 页面只负责展示和收集输入，登录/注册/退出等异步编排都收敛在这里。
class AuthNotifier extends ChangeNotifier {
  final AuthService _authService;
  final TokenStore _tokenStore;

  AuthStatus _status = AuthStatus.restoring;
  UserInfo? _user;
  String? _errorMessage;

  AuthNotifier({
    required AuthService authService,
    required TokenStore tokenStore,
  })  : _authService = authService,
        _tokenStore = tokenStore;

  AuthStatus get status => _status;
  UserInfo? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// 清空错误提示，页面进入时调用，避免展示上一次操作留下的旧错误。
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// 冷启动恢复登录态。
  ///
  /// 流程：本地有 token → 调 `/api/user/me` 校验 → 有效则进入已登录，
  /// 无效（token 过期/被拉黑）则清掉本地 token 回到未登录。
  /// 无论结果如何都以 unauthenticated/authenticated 收尾，不会停留在 restoring。
  Future<void> restoreSession() async {
    final String? token = await _tokenStore.readToken();

    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      _user = await _authService.fetchCurrentUser();
      _status = AuthStatus.authenticated;
    } catch (e) {
      // token 已失效时后端会拒绝 /api/user/me，此时本地凭证不再可信。
      await _tokenStore.clearToken();
      _user = null;
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// 账号密码登录。
  ///
  /// 返回 true 表示登录成功（页面据此关闭登录页）；
  /// 失败时把后端提示写入 [errorMessage]，返回 false。
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final LoginResult result = await _authService.login(
        username: username,
        password: password,
      );
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = _readableError(e, fallback: '登录失败，请稍后重试');
      notifyListeners();
      return false;
    }
  }

  /// 注册并自动登录。
  ///
  /// 后端注册接口不返回 token，所以成功后直接复用 [login] 走一遍登录。
  Future<bool> register({
    required String username,
    required String password,
    String? nickname,
    String? phone,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(
        username: username,
        password: password,
        nickname: nickname,
        phone: phone,
      );
    } catch (e) {
      _errorMessage = _readableError(e, fallback: '注册失败，请稍后重试');
      notifyListeners();
      return false;
    }

    return login(username: username, password: password);
  }

  /// 退出登录。
  ///
  /// 后端调用失败（如 token 已失效）不影响本地退出：
  /// 先本地清状态，再尽力通知后端拉黑 token。
  Future<void> logout() async {
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    await _tokenStore.clearToken();
    notifyListeners();

    try {
      await _authService.logout();
    } catch (_) {
      // 后端登出失败不阻塞本地退出，token 已清除，下次请求自然未认证。
    }
  }

  /// 把异常转换成用户能看懂的提示。
  ///
  /// 后端业务错误（如“用户名或密码错误”）优先展示后端 message，
  /// 网络异常则使用兜底文案。
  String _readableError(Object error, {required String fallback}) {
    if (error is ApiException) {
      return error.message;
    }

    return fallback;
  }
}
