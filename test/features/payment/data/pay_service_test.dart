import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/payment/data/models/pay_result_vo.dart';
import 'package:my_first_app/features/payment/data/pay_service.dart';
import '../../../helpers/http_body_helpers.dart';
import '../../../helpers/mocks.mocks.dart';

void main() {
  // 每个用例独立一套 ApiClient + Mock adapter，互不影响。
  late MockHttpClientAdapter adapter;

  PayService buildService() {
    adapter = MockHttpClientAdapter();
    final ApiClient apiClient = ApiClient(
      baseUrl: 'http://test.local',
      adapter: adapter,
    );
    return PayService(apiClient: apiClient);
  }

  RequestOptions capturedRequest() {
    return verify(adapter.fetch(captureAny, any, any)).captured.single
        as RequestOptions;
  }

  test('mockPay POST /api/pay/{orderNo}/mockPay 并解析支付结果', () async {
    final PayService service = buildService();
    when(adapter.fetch(any, any, any)).thenAnswer((_) async {
      return jsonResponseBody(<String, dynamic>{
        'code': 200,
        'message': 'ok',
        'data': <String, dynamic>{
          'orderNo': '20260101100001',
          'amount': 89.0,
          'status': 1,
          'payTime': '2026-01-01 10:05:00',
        },
      });
    });

    final PayResultVO result = await service.mockPay('20260101100001');

    final RequestOptions request = capturedRequest();
    expect(request.method, 'POST');
    expect(request.uri.path, '/api/pay/20260101100001/mockPay');

    expect(result.orderNo, '20260101100001');
    expect(result.amount, 89.0);
    expect(result.status, PayResultVO.statusSuccess);
    expect(result.isSuccess, isTrue);
    expect(result.payTime, '2026-01-01 10:05:00');
    expect(result.payAmountLabel, '¥89');
  });

  test('业务失败时抛出带后端提示的 ApiException', () async {
    final PayService service = buildService();
    when(adapter.fetch(any, any, any)).thenAnswer((_) async {
      return jsonResponseBody(<String, dynamic>{
        'code': 1005,
        'message': '订单状态不支持支付',
        'data': null,
      });
    });

    await expectLater(
      service.mockPay('20260101100001'),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.message,
          'message',
          '订单状态不支持支付',
        ),
      ),
    );
  });
}
