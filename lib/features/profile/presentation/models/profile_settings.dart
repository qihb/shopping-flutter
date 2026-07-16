/// 我的页面里的基础设置。
///
/// 这里先用几个布尔值来模拟常见的个人设置项，
/// 后面如果复杂度上升，再考虑拆成更细的设置模块。
class ProfileSettings {
  final bool enableNotification;
  final bool enableBiometricUnlock;
  final bool enablePriceAlert;

  const ProfileSettings({
    required this.enableNotification,
    required this.enableBiometricUnlock,
    required this.enablePriceAlert,
  });

  ProfileSettings copyWith({
    bool? enableNotification,
    bool? enableBiometricUnlock,
    bool? enablePriceAlert,
  }) {
    return ProfileSettings(
      enableNotification: enableNotification ?? this.enableNotification,
      enableBiometricUnlock:
          enableBiometricUnlock ?? this.enableBiometricUnlock,
      enablePriceAlert: enablePriceAlert ?? this.enablePriceAlert,
    );
  }
}
