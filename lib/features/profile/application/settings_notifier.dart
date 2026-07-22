import 'package:flutter/foundation.dart';

import 'package:my_first_app/features/profile/presentation/models/profile_settings.dart';

/// 基础设置状态管理。
///
/// 它负责管理消息通知、生物解锁、降价提醒等开关状态。
class SettingsNotifier extends ChangeNotifier {
  ProfileSettings _settings;

  SettingsNotifier({ProfileSettings initialSettings = const ProfileSettings(
    enableNotification: true,
    enableBiometricUnlock: false,
    enablePriceAlert: true,
  )}) : _settings = initialSettings;

  /// 当前设置。
  ProfileSettings get settings => _settings;

  /// 切换消息通知。
  void updateNotification(bool value) {
    _settings = _settings.copyWith(enableNotification: value);
    notifyListeners();
  }

  /// 切换生物解锁。
  void updateBiometric(bool value) {
    _settings = _settings.copyWith(enableBiometricUnlock: value);
    notifyListeners();
  }

  /// 切换降价提醒。
  void updatePriceAlert(bool value) {
    _settings = _settings.copyWith(enablePriceAlert: value);
    notifyListeners();
  }
}
