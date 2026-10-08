import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/data/auth_service.dart';
import 'package:my_first_app/features/auth/data/models/user_info.dart';
import '../../../helpers/http_body_helpers.dart';
import '../../../helpers/mocks.mocks.dart';

void main() {
  // 每个用例独立一套 ApiClient + Mock，互不影响。
  late MockTokenStore tokenStore;
  late MockHttpClientAdapter adapter;

  AuthService buildService() {
    adapter = MockHttpClientAdapter();
    final ApiClient apiClient = ApiClient(
      baseUrl: 'http://test.local',
      adapter: adapter,
      tokenProvider: tokenStore.readToken,
    );
    return AuthService(apiClient: apiClient, tokenStore: tokenStore);
  }

  setUp(() {
    tokenStore = MockTokenStore();
    // ApiClient 每次请求都会通过 tokenProvider 读 token，默认未登录。
    when(tokenStore.readToken()).thenAnswer((_) async => null);
  });

  group('AuthService.login', () {
    test('登录成功会携带 X-Client-Id 并把 token 存入本地', () async {
      when(tokenStore.readOrCreateClientId())
          .thenAnswer((_) async => 'test-client-id');
      final AuthService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <String, dynamic>{
            'token': 'jwt-token-123',
            'user': <String, dynamic>{
              'id': 1,
              'username': 'alice',
              'nickname': '小明',
              'phone': '13800001234',
            },
          },
        });
      });

      final LoginResult result = await service.login(
        username: 'alice',
        password: '123456',
      );

      expect(result.token, 'jwt-token-123');
      expect(result.user.displayName, '小明');
      // 登录成功后 token 应交给本地存储持久化。
      verify(tokenStore.saveToken('jwt-token-123')).called(1);

      // 校验请求路径、请求体和 X-Client-Id 请求头。
      final RequestOptions captured =
          verify(adapter.fetch(captureAny, any, any)).captured.single
              as RequestOptions;
      expect(captured.uri.path, '/api/auth/login');
      expect(captured.headers['X-Client-Id'], 'test-client-id');
      final Map<String, dynamic> body = decodedJsonBody(captured);
      expect(body['username'], 'alice');
      expect(body['password'], '123456');
    });

    test('登录业务失败时抛出带后端提示的 ApiException', () async {
      when(tokenStore.readOrCreateClientId())
          .thenAnswer((_) async => 'test-client-id');
      final AuthService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 1002,
          'message': '用户名或密码错误',
          'data': null,
        });
      });

      await expectLater(
        service.login(username: 'alice', password: 'wrong'),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.message,
            'message',
            '用户名或密码错误',
          ),
        ),
      );
      // 登录失败不应写入本地 token。
      verifyNever(tokenStore.saveToken(any));
    });
  });

  test('fetchCurrentUser 会自动携带 Bearer token', () async {
    when(tokenStore.readToken()).thenAnswer((_) async => 'saved-jwt');
    final AuthService service = buildService();
    when(adapter.fetch(any, any, any)).thenAnswer((_) async {
      return jsonResponseBody(<String, dynamic>{
        'code': 200,
        'message': 'ok',
        'data': <String, dynamic>{
          'id': 7,
          'username': 'bob',
          'nickname': '',
          'phone': '',
        },
      });
    });

    final UserInfo user = await service.fetchCurrentUser();

    expect(user.username, 'bob');
    final RequestOptions captured =
        verify(adapter.fetch(captureAny, any, any)).captured.single
            as RequestOptions;
    expect(captured.uri.path, '/api/user/me');
    expect(captured.headers['Authorization'], 'Bearer saved-jwt');
  });

  test('register 的选填字段为空时不会发送', () async {
    final AuthService service = buildService();
    when(adapter.fetch(any, any, any)).thenAnswer((_) async {
      return jsonResponseBody(
        <String, dynamic>{'code': 200, 'message': 'ok', 'data': null},
      );
    });

    await service.register(username: 'newuser', password: '123456');

    final RequestOptions captured =
        verify(adapter.fetch(captureAny, any, any)).captured.single
            as RequestOptions;
    final Map<String, dynamic> body = decodedJsonBody(captured);
    expect(body.keys, containsAll(<String>['username', 'password']));
    expect(body.containsKey('nickname'), isFalse);
    expect(body.containsKey('phone'), isFalse);
  });

  test('HTTP 401 会被翻译成带状态码的 ApiException', () async {
    final AuthService service = buildService();
    when(adapter.fetch(any, any, any)).thenAnswer((_) async {
      return ResponseBody.fromString('{"message":"unauthorized"}', 401);
    });

    await expectLater(
      service.fetchCurrentUser(),
      throwsA(
        isA<ApiException>()
            .having((ApiException e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });
}
