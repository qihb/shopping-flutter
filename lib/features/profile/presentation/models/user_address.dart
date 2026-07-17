/// 收货地址。
///
/// 这里先把地址抽成独立模型，是为了让“我的”页、地址管理页、订单确认页
/// 共享同一份数据结构，而不是在不同页面各自维护散落的字符串。
class UserAddress {
  final String recipientName;
  final String phone;
  final String cityLabel;
  final String detailAddress;
  final bool isDefault;

  const UserAddress({
    required this.recipientName,
    required this.phone,
    required this.cityLabel,
    required this.detailAddress,
    this.isDefault = false,
  });

  String get fullAddress => '$cityLabel$detailAddress';

  UserAddress copyWith({
    String? recipientName,
    String? phone,
    String? cityLabel,
    String? detailAddress,
    bool? isDefault,
  }) {
    return UserAddress(
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      cityLabel: cityLabel ?? this.cityLabel,
      detailAddress: detailAddress ?? this.detailAddress,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
