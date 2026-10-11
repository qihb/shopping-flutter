/// 收货地址（服务端出参）。
///
/// 对接 spring-shop 的 `AddressVO`：省、市、区在后端是三个独立字段，
/// 展示时拼接为一段地区文案；详情页、地址管理页与下单入口共享该模型。
class AddressVO {
  final int id;
  final String receiverName;
  final String receiverPhone;

  /// 省份、城市、区/县。
  ///
  /// 直辖市（如上海市）的省和市取值相同，展示时按 [regionLabel] 去重。
  final String province;
  final String city;
  final String district;
  final String detailAddress;
  final bool isDefault;

  const AddressVO({
    required this.id,
    required this.receiverName,
    required this.receiverPhone,
    required this.province,
    required this.city,
    required this.district,
    required this.detailAddress,
    this.isDefault = false,
  });

  factory AddressVO.fromJson(Map<String, dynamic> json) {
    return AddressVO(
      id: json['id'] as int,
      receiverName: json['receiverName'] as String? ?? '',
      receiverPhone: json['receiverPhone'] as String? ?? '',
      province: json['province'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      detailAddress: json['detailAddress'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// 省市区地区文案。
  ///
  /// 直辖市的省和市相同（“上海市上海市浦东新区”），
  /// 省市一致时只保留一份，让文案保持自然。
  String get regionLabel {
    if (province.isEmpty) {
      return '$city$district';
    }
    if (province == city) {
      return '$province$district';
    }
    return '$province$city$district';
  }

  /// 完整收货地址：省市区 + 详细地址。
  String get fullAddress => '$regionLabel$detailAddress';

  AddressVO copyWith({
    int? id,
    String? receiverName,
    String? receiverPhone,
    String? province,
    String? city,
    String? district,
    String? detailAddress,
    bool? isDefault,
  }) {
    return AddressVO(
      id: id ?? this.id,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      province: province ?? this.province,
      city: city ?? this.city,
      district: district ?? this.district,
      detailAddress: detailAddress ?? this.detailAddress,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
