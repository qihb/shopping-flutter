import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_result.dart';
import 'package:my_first_app/features/auth/data/models/user_info.dart';
import 'package:my_first_app/features/auth/data/token_store.dart';

/// 认证数据服务，对接 spring-shop 的认证接口。
///
/// 与 [HomeRecommendService] 的分层思路一致：
/// - [ApiClient] 负责 baseUrl、请求头、token 注入和 HTTP 异常
/// - 本服务负责 `Result<T>` 解包和 JSON 到模型的映射
class AuthService {
  final ApiClient _apiClient;
  final TokenStore _tokenStore;

  AuthService({required ApiClient apiClient, required TokenStore tokenStore})
      : _apiClient = apiClient,
        _tokenStore = tokenStore;

  /// 账号密码登录。
  ///
  /// 后端通过 `X-Client-Id` 请求头识别登录设备，登录成功后
  /// token 交给 [TokenStore] 持久化，后续请求由 [ApiClient] 自动携带。
  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final String clientId = await _tokenStore.readOrCreateClientId();
    final dynamic data = parseResultData(
      await _apiClient.post(
        '/api/auth/login',
        body: <String, dynamic>{'username': username, 'password': password},
        headers: <String, String>{'X-Client-Id': clientId},
      ),
    );

    final LoginResult result =
        LoginResult.fromJson(data as Map<String, dynamic>);
    await _tokenStore.saveToken(result.token);
    return result;
  }

  /// 注册新用户。
  ///
  /// 用户名唯一，昵称和手机号选填；成功后没有返回数据，
  /// 通常注册完紧接着调用 [login] 完成自动登录。
  Future<void> register({
    required String username,
    required String password,
    String? nickname,
    String? phone,
  }) async {
    await parseResultData(
      await _apiClient.post(
        '/api/auth/register',
        body: <String, dynamic>{
          'username': username,
          'password': password,
          if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      ),
    );
  }

  /// 退出登录。
  ///
  /// 后端会把当前 token 加入黑名单主动失效；
  /// 无论后端调用是否成功，本地 token 都应清掉，所以异常由调用方兜底。
  Future<void> logout() async {
    await parseResultData(await _apiClient.post('/api/auth/logout'));
    await _tokenStore.clearToken();
  }

  /// 获取当前登录用户信息，用于冷启动时校验本地 token 是否仍然有效。
  Future<UserInfo> fetchCurrentUser() async {
    final dynamic data =
        parseResultData(await _apiClient.get('/api/user/me'));
    return UserInfo.fromJson(data as Map<String, dynamic>);
  }
}
