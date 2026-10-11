import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_result.dart';
import 'package:my_first_app/features/profile/data/models/address_vo.dart';

/// 收货地址域数据服务，对接 spring-shop 的地址接口。
///
/// 与购物车 [CartService] 的分层思路一致：
/// - [ApiClient] 负责 baseUrl、token 注入和 HTTP 异常
/// - 本服务负责 `Result<T>` 解包和 JSON 到模型的映射
///
/// 注意：除 `POST /api/addresses` 返回新地址 id 外，
/// 其余变更接口都只返回 `Result<Void>`，成功即视为生效；
/// 最新列表需要调用方重新拉取 [fetchAddresses] 获得。
class AddressService {
  final ApiClient _apiClient;

  AddressService({required this._apiClient});

  /// 我的地址列表（默认地址在前）。
  Future<List<AddressVO>> fetchAddresses() async {
    final dynamic data = parseResultData(await _apiClient.get('/api/addresses'));
    return (data as List<dynamic>)
        .map((dynamic item) => AddressVO.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// 新增地址，返回服务端生成的新地址 id。
  Future<int> addAddress({
    required String receiverName,
    required String receiverPhone,
    required String province,
    required String city,
    required String district,
    required String detailAddress,
    bool isDefault = false,
  }) async {
    final dynamic data = parseResultData(
      await _apiClient.post(
        '/api/addresses',
        body: _saveBody(
          receiverName: receiverName,
          receiverPhone: receiverPhone,
          province: province,
          city: city,
          district: district,
          detailAddress: detailAddress,
          isDefault: isDefault,
        ),
      ),
    );
    return data as int;
  }

  /// 修改地址。
  Future<void> updateAddress({
    required int id,
    required String receiverName,
    required String receiverPhone,
    required String province,
    required String city,
    required String district,
    required String detailAddress,
    bool isDefault = false,
  }) async {
    await parseResultData(
      await _apiClient.put(
        '/api/addresses/$id',
        body: _saveBody(
          receiverName: receiverName,
          receiverPhone: receiverPhone,
          province: province,
          city: city,
          district: district,
          detailAddress: detailAddress,
          isDefault: isDefault,
        ),
      ),
    );
  }

  /// `AddressSaveRequest` 入参，新增与修改共用同一份字段。
  Map<String, dynamic> _saveBody({
    required String receiverName,
    required String receiverPhone,
    required String province,
    required String city,
    required String district,
    required String detailAddress,
    required bool isDefault,
  }) {
    return <String, dynamic>{
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'province': province,
      'city': city,
      'district': district,
      'detailAddress': detailAddress,
      'isDefault': isDefault,
    };
  }

  /// 删除单条地址。
  Future<void> deleteAddress(int id) async {
    await parseResultData(await _apiClient.delete('/api/addresses/$id'));
  }

  /// 设为默认地址（后端会自动取消原默认地址）。
  Future<void> setDefaultAddress(int id) async {
    await parseResultData(await _apiClient.put('/api/addresses/$id/default'));
  }
}
