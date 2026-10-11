import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/profile/data/address_service.dart';
import 'package:my_first_app/features/profile/data/models/address_vo.dart';
import '../../../helpers/http_body_helpers.dart';
import '../../../helpers/mocks.mocks.dart';

void main() {
  // 每个用例独立一套 ApiClient + Mock adapter，互不影响。
  late MockHttpClientAdapter adapter;

  AddressService buildService() {
    adapter = MockHttpClientAdapter();
    final ApiClient apiClient = ApiClient(
      baseUrl: 'http://test.local',
      adapter: adapter,
    );
    return AddressService(apiClient: apiClient);
  }

  RequestOptions capturedRequest() {
    return verify(adapter.fetch(captureAny, any, any)).captured.single
        as RequestOptions;
  }

  group('AddressService.fetchAddresses', () {
    test('请求 GET /api/addresses 并解析地址列表字段', () async {
      final AddressService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'receiverName': 'Qi Hai Bing',
              'receiverPhone': '13800001234',
              'province': '上海市',
              'city': '上海市',
              'district': '浦东新区',
              'detailAddress': '张江高科',
              'isDefault': true,
            },
            <String, dynamic>{
              'id': 2,
              'receiverName': '测试收货人',
              'receiverPhone': '13900005678',
              'province': '江苏省',
              'city': '苏州市',
              'district': '工业园区',
              'detailAddress': '金鸡湖大道',
            },
          ],
        });
      });

      final List<AddressVO> addresses = await service.fetchAddresses();

      final RequestOptions request = capturedRequest();
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/addresses');

      expect(addresses, hasLength(2));

      final AddressVO first = addresses.first;
      expect(first.id, 1);
      expect(first.receiverName, 'Qi Hai Bing');
      expect(first.receiverPhone, '13800001234');
      expect(first.province, '上海市');
      expect(first.city, '上海市');
      expect(first.district, '浦东新区');
      expect(first.detailAddress, '张江高科');
      expect(first.isDefault, isTrue);
      // 直辖市的省和市相同，地区文案去重后只保留一份「上海市」。
      expect(first.regionLabel, '上海市浦东新区');
      expect(first.fullAddress, '上海市浦东新区张江高科');

      final AddressVO second = addresses.last;
      expect(second.id, 2);
      expect(second.regionLabel, '江苏省苏州市工业园区');
      expect(second.isDefault, isFalse);
    });

    test('可选字段缺失时回退为空字符串与 false', () async {
      final AddressService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <Map<String, dynamic>>[
            <String, dynamic>{'id': 1},
          ],
        });
      });

      final List<AddressVO> addresses = await service.fetchAddresses();

      final AddressVO only = addresses.single;
      expect(only.receiverName, '');
      expect(only.receiverPhone, '');
      expect(only.province, '');
      expect(only.city, '');
      expect(only.district, '');
      expect(only.detailAddress, '');
      expect(only.isDefault, isFalse);
    });
  });

  group('AddressService.addAddress', () {
    test('POST /api/addresses，请求体携带完整保存字段，返回新地址 id', () async {
      final AddressService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': 100,
        });
      });

      final int newId = await service.addAddress(
        receiverName: 'Qi Hai Bing',
        receiverPhone: '13800001234',
        province: '上海市',
        city: '上海市',
        district: '浦东新区',
        detailAddress: '张江高科',
        isDefault: true,
      );

      expect(newId, 100);

      final RequestOptions request = capturedRequest();
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/addresses');
      expect(decodedJsonBody(request), <String, dynamic>{
        'receiverName': 'Qi Hai Bing',
        'receiverPhone': '13800001234',
        'province': '上海市',
        'city': '上海市',
        'district': '浦东新区',
        'detailAddress': '张江高科',
        'isDefault': true,
      });
    });

    test('isDefault 未传时默认为 false', () async {
      final AddressService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': 100,
        });
      });

      await service.addAddress(
        receiverName: 'Qi Hai Bing',
        receiverPhone: '13800001234',
        province: '上海市',
        city: '上海市',
        district: '浦东新区',
        detailAddress: '张江高科',
      );

      expect(decodedJsonBody(capturedRequest())['isDefault'], false);
    });
  });

  group('AddressService.updateAddress', () {
    test('PUT /api/addresses/{id}，请求体携带完整保存字段', () async {
      final AddressService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': null,
        });
      });

      await service.updateAddress(
        id: 5,
        receiverName: '测试收货人',
        receiverPhone: '13900005678',
        province: '江苏省',
        city: '苏州市',
        district: '工业园区',
        detailAddress: '金鸡湖大道',
      );

      final RequestOptions request = capturedRequest();
      expect(request.method, 'PUT');
      expect(request.uri.path, '/api/addresses/5');
      expect(decodedJsonBody(request), <String, dynamic>{
        'receiverName': '测试收货人',
        'receiverPhone': '13900005678',
        'province': '江苏省',
        'city': '苏州市',
        'district': '工业园区',
        'detailAddress': '金鸡湖大道',
        'isDefault': false,
      });
    });
  });

  group('AddressService.deleteAddress', () {
    test('DELETE /api/addresses/{id}', () async {
      final AddressService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': null,
        });
      });

      await service.deleteAddress(5);

      final RequestOptions request = capturedRequest();
      expect(request.method, 'DELETE');
      expect(request.uri.path, '/api/addresses/5');
    });
  });

  group('AddressService.setDefaultAddress', () {
    test('PUT /api/addresses/{id}/default', () async {
      final AddressService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': null,
        });
      });

      await service.setDefaultAddress(5);

      final RequestOptions request = capturedRequest();
      expect(request.method, 'PUT');
      expect(request.uri.path, '/api/addresses/5/default');
    });
  });

  test('业务失败时抛出带后端提示的 ApiException', () async {
    final AddressService service = buildService();
    when(adapter.fetch(any, any, any)).thenAnswer((_) async {
      return jsonResponseBody(<String, dynamic>{
        'code': 1004,
        'message': '地址不存在',
        'data': null,
      });
    });

    await expectLater(
      service.deleteAddress(5),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.message,
          'message',
          '地址不存在',
        ),
      ),
    );
  });
}
