/// 用户信息（对应后端 `UserInfoVO`）。
class UserInfo {
  final int id;
  final String username;
  final String nickname;
  final String phone;

  const UserInfo({
    required this.id,
    required this.username,
    required this.nickname,
    required this.phone,
  });

  /// 展示优先级：昵称 > 用户名，用于“我的”页头部欢迎语。
  String get displayName => nickname.isNotEmpty ? nickname : username;

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

/// 登录成功结果（对应后端 `LoginResponse`）。
class LoginResult {
  /// JWT 凭证，后续请求由 [ApiClient] 自动放入 Authorization 头。
  final String token;
  final UserInfo user;

  const LoginResult({required this.token, required this.user});

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'] as String? ?? '',
      user: UserInfo.fromJson(
        json['user'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}
