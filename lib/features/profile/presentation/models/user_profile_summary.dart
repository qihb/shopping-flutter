/// 我的页面里的个人信息摘要。
///
/// 当前阶段先放最常见的几项基础信息，
/// 这样“我的”页面就不只是入口集合，而是有明确的用户身份展示。
class UserProfileSummary {
  final String displayName;
  final String email;
  final String memberLabel;
  final String defaultAddress;

  const UserProfileSummary({
    required this.displayName,
    required this.email,
    required this.memberLabel,
    required this.defaultAddress,
  });
}
