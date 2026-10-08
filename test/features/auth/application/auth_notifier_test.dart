import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/auth/data/models/user_info.dart';
import '../../../helpers/mocks.mocks.dart';

const LoginResult _successResult = LoginResult(
  token: 'jwt-token',
  user: UserInfo(id: 1, username: 'alice', nickname: '小明', phone: ''),
);

void main() {
  late MockAuthService authService;
  late MockTokenStore tokenStore;

  setUp(() {
    authService = MockAuthService();
    tokenStore = MockTokenStore();
    // 默认按“本地无 token”处理，restoreSession 不会触碰网络。
    when(tokenStore.readToken()).thenAnswer((_) async => null);
  });

  group('AuthNotifier.restoreSession', () {
    test('本地没有 token 时直接进入未登录态，不发起请求', () async {
      final AuthNotifier notifier = AuthNotifier(
        authService: authService,
        tokenStore: tokenStore,
      );

      await notifier.restoreSession();

      expect(notifier.status, AuthStatus.unauthenticated);
      verifyNever(authService.fetchCurrentUser());
    });

    test('本地 token 有效时恢复登录态', () async {
      when(tokenStore.readToken()).thenAnswer((_) async => 'saved-jwt');
      when(authService.fetchCurrentUser()).thenAnswer(
        (_) async => const UserInfo(id: 1, username: 'tester', nickname: '', phone: ''),
      );
      final AuthNotifier notifier = AuthNotifier(
        authService: authService,
        tokenStore: tokenStore,
      );

      await notifier.restoreSession();

      expect(notifier.status, AuthStatus.authenticated);
      expect(notifier.user?.username, 'tester');
      verify(authService.fetchCurrentUser()).called(1);
    });

    test('本地 token 已失效时清除凭证回到未登录态', () async {
      when(tokenStore.readToken()).thenAnswer((_) async => 'expired-jwt');
      when(authService.fetchCurrentUser())
          .thenThrow(const ApiException(message: 'token 已失效'));
      final AuthNotifier notifier = AuthNotifier(
        authService: authService,
        tokenStore: tokenStore,
      );

      await notifier.restoreSession();

      expect(notifier.status, AuthStatus.unauthenticated);
      expect(notifier.user, isNull);
      verify(tokenStore.clearToken()).called(1);
    });
  });

  group('AuthNotifier.login', () {
    test('登录成功进入已登录态', () async {
      when(authService.login(
        username: anyNamed('username'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => _successResult);
      final AuthNotifier notifier = AuthNotifier(
        authService: authService,
        tokenStore: tokenStore,
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
      when(authService.login(
        username: anyNamed('username'),
        password: anyNamed('password'),
      )).thenThrow(const ApiException(message: '用户名或密码错误'));
      final AuthNotifier notifier = AuthNotifier(
        authService: authService,
        tokenStore: tokenStore,
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
      when(authService.login(
        username: anyNamed('username'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => _successResult);
      final AuthNotifier notifier = AuthNotifier(
        authService: authService,
        tokenStore: tokenStore,
      );
      await notifier.restoreSession();
      await notifier.login(username: 'alice', password: '123456');

      await notifier.logout();

      expect(notifier.isAuthenticated, isFalse);
      expect(notifier.user, isNull);
      verify(tokenStore.clearToken()).called(1);
      verify(authService.logout()).called(1);
    });
  });

  group('AuthNotifier.register', () {
    test('注册成功后自动登录', () async {
      when(authService.register(
        username: anyNamed('username'),
        password: anyNamed('password'),
        nickname: anyNamed('nickname'),
        phone: anyNamed('phone'),
      )).thenAnswer((_) async {});
      when(authService.login(
        username: anyNamed('username'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => _successResult);
      final AuthNotifier notifier = AuthNotifier(
        authService: authService,
        tokenStore: tokenStore,
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
      when(authService.register(
        username: anyNamed('username'),
        password: anyNamed('password'),
        nickname: anyNamed('nickname'),
        phone: anyNamed('phone'),
      )).thenAnswer((_) async {});
      when(authService.login(
        username: anyNamed('username'),
        password: anyNamed('password'),
      )).thenThrow(const ApiException(message: '用户名或密码错误'));
      final AuthNotifier notifier = AuthNotifier(
        authService: authService,
        tokenStore: tokenStore,
      );

      // register 打桩为总是成功，随后自动走 login，
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
