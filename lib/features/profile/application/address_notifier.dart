import 'package:flutter/foundation.dart';

import 'package:my_first_app/features/profile/presentation/models/user_address.dart';

/// 收货地址状态管理。
///
/// 它从 `MainTabPage` 中拆出来，负责管理地址列表和默认地址切换。
class AddressNotifier extends ChangeNotifier {
  List<UserAddress> _addresses;

  AddressNotifier({List<UserAddress> initialAddresses = const <UserAddress>[]})
      : _addresses = initialAddresses;

  /// 当前地址列表。
  List<UserAddress> get addresses => _addresses;

  /// 默认地址。
  UserAddress get defaultAddress =>
      _addresses.firstWhere((address) => address.isDefault);

  /// 设置为默认地址。
  void setDefault(UserAddress targetAddress) {
    _addresses = _addresses
        .map(
          (address) => address.copyWith(
            isDefault: address.fullAddress == targetAddress.fullAddress,
          ),
        )
        .toList(growable: false);
    notifyListeners();
  }
}
