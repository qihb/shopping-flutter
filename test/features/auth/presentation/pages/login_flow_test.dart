import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/auth/data/auth_service.dart';
import 'package:my_first_app/features/auth/data/models/user_info.dart';
import 'package:my_first_app/features/auth/data/token_store.dart';
import 'package:my_first_app/features/auth/presentation/pages/login_page.dart';

/// 登录成功的假服务。
class _SuccessAuthService extends AuthService {
  _SuccessAuthService()
      : super(
          apiClient: ApiClient(baseUrl: 'https://test.local'),
          tokenStore: InMemoryTokenStore(),
        );

  @override
  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    return LoginResult(
      token: 'jwt-token',
      user: UserInfo(id: 1, username: username, nickname: '', phone: ''),
    );
  }
}

/// 登录失败的假服务。
class _FailureAuthService extends AuthService {
  _FailureAuthService()
      : super(
          apiClient: ApiClient(baseUrl: 'https://test.local'),
          tokenStore: InMemoryTokenStore(),
        );

  @override
  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    throw const ApiException(message: '用户名或密码错误');
  }
}

Widget _buildTestApp(AuthNotifier notifier) {
  return ChangeNotifierProvider<AuthNotifier>.value(
    value: notifier,
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const LoginPage(),
                ),
              ),
              child: const Text('打开登录页'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _submitLoginForm(
  WidgetTester tester, {
  String username = 'alice',
  String password = '123456',
}) async {
  await tester.enterText(find.byKey(const ValueKey<String>('login-username')), username);
  await tester.enterText(find.byKey(const ValueKey<String>('login-password')), password);
  await tester.tap(find.byKey(const ValueKey<String>('login-submit')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('登录成功后会关闭登录页并更新登录态', (WidgetTester tester) async {
    final AuthNotifier notifier = AuthNotifier(
      authService: _SuccessAuthService(),
      tokenStore: InMemoryTokenStore(),
    )..restoreSession();

    await tester.pumpWidget(_buildTestApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开登录页'));
    await tester.pumpAndSettle();
    expect(find.text('欢迎回来'), findsOneWidget);

    await _submitLoginForm(tester);

    // 登录成功后登录页自动关闭，回到外层页面。
    expect(find.text('欢迎回来'), findsNothing);
    expect(find.text('打开登录页'), findsOneWidget);
    expect(notifier.isAuthenticated, isTrue);
    expect(notifier.user?.username, 'alice');
  });

  testWidgets('登录失败时页面不关闭并展示后端错误信息', (WidgetTester tester) async {
    final AuthNotifier notifier = AuthNotifier(
      authService: _FailureAuthService(),
      tokenStore: InMemoryTokenStore(),
    )..restoreSession();

    await tester.pumpWidget(_buildTestApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开登录页'));
    await tester.pumpAndSettle();

    await _submitLoginForm(tester);

    expect(find.text('欢迎回来'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('login-error-message')),
      findsOneWidget,
    );
    expect(find.text('用户名或密码错误'), findsOneWidget);
    expect(notifier.isAuthenticated, isFalse);
  });

  testWidgets('表单校验：用户名为空时不发起登录', (WidgetTester tester) async {
    final AuthNotifier notifier = AuthNotifier(
      authService: _SuccessAuthService(),
      tokenStore: InMemoryTokenStore(),
    )..restoreSession();

    await tester.pumpWidget(_buildTestApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开登录页'));
    await tester.pumpAndSettle();

    // 只填密码不填用户名，应被表单校验拦截。
    await tester.enterText(
      find.byKey(const ValueKey<String>('login-password')),
      '123456',
    );
    await tester.tap(find.byKey(const ValueKey<String>('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('请输入用户名'), findsOneWidget);
    expect(notifier.isAuthenticated, isFalse);
  });

  testWidgets('可以跳转到注册页', (WidgetTester tester) async {
    final AuthNotifier notifier = AuthNotifier(
      authService: _SuccessAuthService(),
      tokenStore: InMemoryTokenStore(),
    )..restoreSession();

    await tester.pumpWidget(_buildTestApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开登录页'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('login-go-register')));
    await tester.pumpAndSettle();

    expect(find.text('创建账号'), findsOneWidget);
  });
}
