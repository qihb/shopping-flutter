import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/auth/data/models/user_info.dart';
import 'package:my_first_app/features/auth/presentation/pages/login_page.dart';
import '../../../../helpers/mocks.mocks.dart';

/// 创建测试用的登录态管理：token 存取走 Mock，restoreSession 后处于未登录态。
AuthNotifier buildAuthNotifier({
  required MockAuthService authService,
  required MockTokenStore tokenStore,
}) {
  return AuthNotifier(
    authService: authService,
    tokenStore: tokenStore,
  )..restoreSession();
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
  late MockAuthService authService;
  late MockTokenStore tokenStore;

  setUp(() {
    authService = MockAuthService();
    tokenStore = MockTokenStore();
    // 本地无 token，restoreSession 后进入未登录态。
    when(tokenStore.readToken()).thenAnswer((_) async => null);
  });

  testWidgets('登录成功后会关闭登录页并更新登录态', (WidgetTester tester) async {
    when(authService.login(
      username: anyNamed('username'),
      password: anyNamed('password'),
    )).thenAnswer((Invocation invocation) async {
      // 登录服务会用提交的用户名构造用户信息，这里保持同样行为。
      return LoginResult(
        token: 'jwt-token',
        user: UserInfo(
          id: 1,
          username: invocation.namedArguments[#username] as String,
          nickname: '',
          phone: '',
        ),
      );
    });
    final AuthNotifier notifier = buildAuthNotifier(
      authService: authService,
      tokenStore: tokenStore,
    );

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
    when(authService.login(
      username: anyNamed('username'),
      password: anyNamed('password'),
    )).thenThrow(const ApiException(message: '用户名或密码错误'));
    final AuthNotifier notifier = buildAuthNotifier(
      authService: authService,
      tokenStore: tokenStore,
    );

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
    when(authService.login(
      username: anyNamed('username'),
      password: anyNamed('password'),
    )).thenAnswer((_) async {
      return LoginResult(
        token: 'jwt-token',
        user: const UserInfo(id: 1, username: 'alice', nickname: '', phone: ''),
      );
    });
    final AuthNotifier notifier = buildAuthNotifier(
      authService: authService,
      tokenStore: tokenStore,
    );

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
    // 校验拦截后不应触发登录服务。
    verifyNever(authService.login(
      username: anyNamed('username'),
      password: anyNamed('password'),
    ));
  });

  testWidgets('可以跳转到注册页', (WidgetTester tester) async {
    final AuthNotifier notifier = buildAuthNotifier(
      authService: authService,
      tokenStore: tokenStore,
    );

    await tester.pumpWidget(_buildTestApp(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开登录页'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('login-go-register')));
    await tester.pumpAndSettle();

    expect(find.text('创建账号'), findsOneWidget);
  });
}
