import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// 登录凭证与设备标识的本地存储接口。
///
/// 抽象成接口是为了让 [ApiClient] 的 tokenProvider、[AuthNotifier] 的会话恢复
/// 不依赖具体存储实现，测试时可以注入内存版避免依赖平台通道。
abstract class TokenStore {
  /// 读取已保存的登录 token，未登录返回 null。
  Future<String?> readToken();

  /// 保存登录 token（登录成功时调用）。
  Future<void> saveToken(String token);

  /// 清空登录 token（退出登录或 token 失效时调用）。
  Future<void> clearToken();

  /// 读取设备 clientId，首次调用时生成并持久化。
  ///
  /// 后端登录接口通过 `X-Client-Id` 请求头识别发起登录的设备，
  /// 同一设备多次登录应使用同一个 clientId，所以需要持久化。
  Future<String> readOrCreateClientId();
}

/// 基于生产环境真实存储的实现。
class SharedPrefsTokenStore implements TokenStore {
  static const String _tokenKey = 'auth_token';
  static const String _clientIdKey = 'device_client_id';

  @override
  Future<String?> readToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  @override
  Future<void> clearToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  @override
  Future<String> readOrCreateClientId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_clientIdKey);

    if (saved != null) {
      return saved;
    }

    final String clientId = _generateClientId();
    await prefs.setString(_clientIdKey, clientId);
    return clientId;
  }

  /// 生成一个足够唯一的 clientId。
  ///
  /// 这里用“毫秒时间戳 + 随机数”拼出 32 位十六进制字符串，
  /// 避免为了一个 id 再引入 `uuid` 这类第三方包。
  static String _generateClientId() {
    final Random random = Random();
    final StringBuffer buffer = StringBuffer(
      DateTime.now().millisecondsSinceEpoch.toRadixString(16),
    );

    while (buffer.length < 32) {
      buffer.write(random.nextInt(16).toRadixString(16));
    }

    return buffer.toString().substring(0, 32);
  }
}
