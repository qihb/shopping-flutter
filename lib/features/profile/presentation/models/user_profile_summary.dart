/// 我的页面里的个人信息摘要。
///
/// 登录前展示访客视图，登录后由 [UserInfo] 映射而来，
/// 所以 email 和 phone 允许为空（后端 UserInfoVO 里两者都可能没有值）。
class UserProfileSummary {
  final String displayName;
  final String email;
  final String phone;
  final String memberLabel;
  final String defaultAddress;

  const UserProfileSummary({
    required this.displayName,
    this.email = '',
    this.phone = '',
    required this.memberLabel,
    required this.defaultAddress,
  });

  UserProfileSummary copyWith({
    String? displayName,
    String? email,
    String? phone,
    String? memberLabel,
    String? defaultAddress,
  }) {
    return UserProfileSummary(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      memberLabel: memberLabel ?? this.memberLabel,
      defaultAddress: defaultAddress ?? this.defaultAddress,
    );
  }
}
