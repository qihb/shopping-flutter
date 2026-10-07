import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/auth/data/auth_service.dart';
import 'package:my_first_app/features/auth/data/models/user_info.dart';
import 'package:my_first_app/features/auth/data/token_store.dart';

/// 可配置行为的登录服务假实现。
///
/// 通过 [loginResult] 控制登录成功还是抛出业务异常，
/// 其余方法只记录调用，不发起真实网络请求。
class _StubAuthService extends AuthService {
  final Object? loginResult;

  /// fetchCurrentUser 的返回值，传异常对象可模拟“本地 token 已失效”。
  final Object? currentUserResult;
  int logoutCallCount = 0;
  int fetchCurrentUserCallCount = 0;

  _StubAuthService({this.loginResult, this.currentUserResult})
      : super(
          apiClient: ApiClient(baseUrl: 'https://test.local'),
          tokenStore: InMemoryTokenStore(),
        );

  @override
  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final Object? result = loginResult;
    if (result is LoginResult) {
      return result;
    }
    throw result ?? const ApiException(message: '登录失败');
  }

  @override
  Future<void> register({
    required String username,
    required String password,
    String? nickname,
    String? phone,
  }) async {}

  @override
  Future<void> logout() async {
    logoutCallCount++;
  }

  @override
  Future<UserInfo> fetchCurrentUser() async {
    fetchCurrentUserCallCount++;
    final Object? result = currentUserResult;
    if (result is UserInfo) {
      return result;
    }
    if (result != null) {
      throw result;
    }
    return const UserInfo(id: 1, username: 'tester', nickname: '', phone: '');
  }
}

const LoginResult _successResult = LoginResult(
  token: 'jwt-token',
  user: UserInfo(id: 1, username: 'alice', nickname: '小明', phone: ''),
);

void main() {
  group('AuthNotifier.restoreSession', () {
    test('本地没有 token 时直接进入未登录态，不发起请求', () async {
      final _StubAuthService service = _StubAuthService();
      final AuthNotifier notifier = AuthNotifier(
        authService: service,
        tokenStore: InMemoryTokenStore(),
      );

      await notifier.restoreSession();

      expect(notifier.status, AuthStatus.unauthenticated);
      expect(service.fetchCurrentUserCallCount, 0);
    });

    test('本地 token 有效时恢复登录态', () async {
      final _StubAuthService service = _StubAuthService();
      final AuthNotifier notifier = AuthNotifier(
        authService: service,
        tokenStore: InMemoryTokenStore(token: 'saved-jwt'),
      );

      await notifier.restoreSession();

      expect(notifier.status, AuthStatus.authenticated);
      expect(notifier.user?.username, 'tester');
      expect(service.fetchCurrentUserCallCount, 1);
    });

    test('本地 token 已失效时清除凭证回到未登录态', () async {
      final _StubAuthService service = _StubAuthService(
        currentUserResult: const ApiException(message: 'token 已失效'),
      );
      final InMemoryTokenStore tokenStore =
          InMemoryTokenStore(token: 'expired-jwt');
      final AuthNotifier notifier = AuthNotifier(
        authService: service,
        tokenStore: tokenStore,
      );

      await notifier.restoreSession();

      expect(notifier.status, AuthStatus.unauthenticated);
      expect(notifier.user, isNull);
      expect(tokenStore.token, isNull);
    });
  });

  group('AuthNotifier.login', () {
    test('登录成功进入已登录态', () async {
      final AuthNotifier notifier = AuthNotifier(
        authService: _StubAuthService(loginResult: _successResult),
        tokenStore: InMemoryTokenStore(),
      );
      await notifier.restoreSession();

      final bool didSucceed = await notifier.login(
        username: 'alice',
        password: '123456',
      );

      expect(didSucceed, isTrue);
      expect(notifier.isAuthenticated, isTrue);
      expect(notifier.user?.displayName, '小明');
    });

    test('登录失败回到未登录态并记录错误信息', () async {
      final AuthNotifier notifier = AuthNotifier(
        authService: _StubAuthService(
          loginResult: const ApiException(message: '用户名或密码错误'),
        ),
        tokenStore: InMemoryTokenStore(),
      );
      await notifier.restoreSession();

      final bool didSucceed = await notifier.login(
        username: 'alice',
        password: 'wrong',
      );

      expect(didSucceed, isFalse);
      expect(notifier.isAuthenticated, isFalse);
      expect(notifier.errorMessage, '用户名或密码错误');
    });
  });

  group('AuthNotifier.logout', () {
    test('退出登录会清空用户并通知后端', () async {
      final _StubAuthService service =
          _StubAuthService(loginResult: _successResult);
      final InMemoryTokenStore tokenStore = InMemoryTokenStore();
      final AuthNotifier notifier = AuthNotifier(
        authService: service,
        tokenStore: tokenStore,
      );
      await notifier.restoreSession();
      await notifier.login(username: 'alice', password: '123456');

      await notifier.logout();

      expect(notifier.isAuthenticated, isFalse);
      expect(notifier.user, isNull);
      expect(tokenStore.token, isNull);
      expect(service.logoutCallCount, 1);
    });
  });

  group('AuthNotifier.register', () {
    test('注册成功后自动登录', () async {
      final AuthNotifier notifier = AuthNotifier(
        authService: _StubAuthService(loginResult: _successResult),
        tokenStore: InMemoryTokenStore(),
      );
      await notifier.restoreSession();

      final bool didSucceed = await notifier.register(
        username: 'alice',
        password: '123456',
      );

      expect(didSucceed, isTrue);
      expect(notifier.isAuthenticated, isTrue);
    });

    test('注册成功但自动登录失败时回到未登录并提示错误', () async {
      final AuthNotifier notifier = AuthNotifier(
        authService: _StubAuthService(
          loginResult: const ApiException(message: '用户名或密码错误'),
        ),
        tokenStore: InMemoryTokenStore(),
      );

      // register 在假实现里总是成功，随后自动走 login，
      // 而 login 被配置为抛出业务异常，用来验证失败路径的状态兜底。
      final bool didSucceed = await notifier.register(
        username: 'alice',
        password: '123456',
      );

      expect(didSucceed, isFalse);
      expect(notifier.errorMessage, '用户名或密码错误');
      expect(notifier.isAuthenticated, isFalse);
    });
  });
}
