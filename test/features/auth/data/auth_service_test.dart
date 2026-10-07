import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/auth/data/auth_service.dart';
import 'package:my_first_app/features/auth/data/models/user_info.dart';
import 'package:my_first_app/features/auth/data/token_store.dart';
import '../../../helpers/mock_api_adapter.dart';

void main() {
  // 每个用例独立一套 ApiClient + 内存存储，互不影响。
  late InMemoryTokenStore tokenStore;
  late CapturingMockAdapter adapter;

  AuthService buildService() {
    adapter = CapturingMockAdapter(responder: (options) {
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
    final ApiClient apiClient = ApiClient(
      baseUrl: 'http://test.local',
      adapter: adapter,
      tokenProvider: tokenStore.readToken,
    );
    return AuthService(apiClient: apiClient, tokenStore: tokenStore);
  }

  setUp(() {
    tokenStore = InMemoryTokenStore();
  });

  group('AuthService.login', () {
    test('登录成功会携带 X-Client-Id 并把 token 存入本地', () async {
      final AuthService service = buildService();

      final LoginResult result = await service.login(
        username: 'alice',
        password: '123456',
      );

      expect(result.token, 'jwt-token-123');
      expect(result.user.displayName, '小明');
      expect(tokenStore.token, 'jwt-token-123');

      // 校验请求路径、请求体和 X-Client-Id 请求头。
      expect(adapter.captured.single.uri.path, '/api/auth/login');
      expect(adapter.captured.single.headers['X-Client-Id'], 'test-client-id');
      final Map<String, dynamic> body =
          decodedJsonBody(adapter.captured.single);
      expect(body['username'], 'alice');
      expect(body['password'], '123456');
    });

    test('登录业务失败时抛出带后端提示的 ApiException', () async {
      adapter = CapturingMockAdapter(responder: (options) {
        return jsonResponseBody(<String, dynamic>{
          'code': 1002,
          'message': '用户名或密码错误',
          'data': null,
        });
      });
      final ApiClient apiClient = ApiClient(
        baseUrl: 'http://test.local',
        adapter: adapter,
        tokenProvider: tokenStore.readToken,
      );
      final AuthService service = AuthService(
        apiClient: apiClient,
        tokenStore: tokenStore,
      );

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
      expect(tokenStore.token, isNull);
    });
  });

  test('fetchCurrentUser 会自动携带 Bearer token', () async {
    tokenStore.token = 'saved-jwt';
    adapter = CapturingMockAdapter(responder: (options) {
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
    final ApiClient apiClient = ApiClient(
      baseUrl: 'http://test.local',
      adapter: adapter,
      tokenProvider: tokenStore.readToken,
    );
    final AuthService service = AuthService(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );

    final UserInfo user = await service.fetchCurrentUser();

    expect(user.username, 'bob');
    expect(adapter.captured.single.uri.path, '/api/user/me');
    expect(
      adapter.captured.single.headers['Authorization'],
      'Bearer saved-jwt',
    );
  });

  test('register 的选填字段为空时不会发送', () async {
    adapter = CapturingMockAdapter(responder: (options) {
      return jsonResponseBody(
        <String, dynamic>{'code': 200, 'message': 'ok', 'data': null},
      );
    });
    final ApiClient apiClient = ApiClient(
      baseUrl: 'http://test.local',
      adapter: adapter,
      tokenProvider: tokenStore.readToken,
    );
    final AuthService service = AuthService(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );

    await service.register(username: 'newuser', password: '123456');

    final Map<String, dynamic> body =
        decodedJsonBody(adapter.captured.single);
    expect(body.keys, containsAll(<String>['username', 'password']));
    expect(body.containsKey('nickname'), isFalse);
    expect(body.containsKey('phone'), isFalse);
  });

  test('HTTP 401 会被翻译成带状态码的 ApiException', () async {
    adapter = CapturingMockAdapter(responder: (options) {
      return ResponseBody.fromString('{"message":"unauthorized"}', 401);
    });
    final ApiClient apiClient = ApiClient(
      baseUrl: 'http://test.local',
      adapter: adapter,
      tokenProvider: tokenStore.readToken,
    );
    final AuthService service = AuthService(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );

    await expectLater(
      service.fetchCurrentUser(),
      throwsA(
        isA<ApiException>()
            .having((ApiException e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });
}
