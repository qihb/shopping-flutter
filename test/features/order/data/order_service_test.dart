import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/order/data/models/order_status.dart';
import 'package:my_first_app/features/order/data/models/order_vo.dart';
import 'package:my_first_app/features/order/data/order_service.dart';
import '../../../helpers/http_body_helpers.dart';
import '../../../helpers/mocks.mocks.dart';

void main() {
  // 每个用例独立一套 ApiClient + Mock adapter，互不影响。
  late MockHttpClientAdapter adapter;

  OrderService buildService() {
    adapter = MockHttpClientAdapter();
    final ApiClient apiClient = ApiClient(
      baseUrl: 'http://test.local',
      adapter: adapter,
    );
    return OrderService(apiClient: apiClient);
  }

  RequestOptions capturedRequest() {
    return verify(adapter.fetch(captureAny, any, any)).captured.single
        as RequestOptions;
  }

  /// 服务端订单列表接口返回的一页数据。
  Map<String, dynamic> orderPageBody(Map<String, dynamic> order) {
    return <String, dynamic>{
      'code': 200,
      'message': 'ok',
      'data': <String, dynamic>{
        'records': <Map<String, dynamic>>[order],
        'total': 1,
        'pages': 1,
        'current': 1,
        'size': 50,
      },
    };
  }

  /// 一条完整的订单 JSON（含明细快照）。
  Map<String, dynamic> fullOrderJson() {
    return <String, dynamic>{
      'id': 1,
      'orderNo': '20260101100001',
      'totalAmount': 89.0,
      'payAmount': 89.0,
      'status': 1,
      'statusDesc': '待付款',
      'receiverName': 'Qi Hai Bing',
      'receiverPhone': '13800001234',
      'receiverAddress': '上海市上海市浦东新区张江高科',
      'remark': '尽快发货',
      'createTime': '2026-01-01 10:00:00',
      'payTime': '',
      'shipTime': '',
      'finishTime': '',
      'cancelTime': '',
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'productId': 1,
          'skuId': 9001,
          'productName': '夏季轻运动鞋',
          'skuSpecs': '默认规格',
          'productImage': '',
          'price': 89.0,
          'quantity': 1,
          'subtotal': 89.0,
        },
      ],
    };
  }

  group('OrderService.fetchOrders', () {
    test('GET /api/orders 默认第一页并解析订单列表字段', () async {
      final OrderService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(orderPageBody(fullOrderJson()));
      });

      final List<OrderVO> orders = await service.fetchOrders();

      final RequestOptions request = capturedRequest();
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/orders');
      expect(request.queryParameters['current'], '1');
      expect(request.queryParameters['size'], '50');

      expect(orders, hasLength(1));

      final OrderVO order = orders.single;
      expect(order.id, 1);
      expect(order.orderNo, '20260101100001');
      expect(order.totalAmount, 89.0);
      expect(order.payAmount, 89.0);
      expect(order.status, OrderStatus.pendingPayment);
      expect(order.statusLabel, '待付款');
      expect(order.receiverName, 'Qi Hai Bing');
      expect(order.receiverPhone, '13800001234');
      expect(order.receiverAddress, '上海市上海市浦东新区张江高科');
      expect(order.remark, '尽快发货');
      expect(order.createTime, '2026-01-01 10:00:00');
      expect(order.canPay, isTrue);

      expect(order.items, hasLength(1));
      expect(order.items.first.productName, '夏季轻运动鞋');
      expect(order.items.first.skuSpecs, '默认规格');
      expect(order.items.first.price, 89.0);
      expect(order.items.first.quantity, 1);
      expect(order.items.first.subtotal, 89.0);
    });

    test('可以指定拉取页码', () async {
      final OrderService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(orderPageBody(fullOrderJson()));
      });

      await service.fetchOrders(current: 2);

      expect(capturedRequest().queryParameters['current'], '2');
    });
  });

  group('OrderService.createOrder', () {
    test('POST /api/orders 请求体携带地址与备注并返回订单号', () async {
      final OrderService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': '20260101100001',
        });
      });

      final String orderNo = await service.createOrder(
        addressId: 5,
        remark: '尽快发货',
      );

      expect(orderNo, '20260101100001');

      final RequestOptions request = capturedRequest();
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/orders');
      expect(decodedJsonBody(request), <String, dynamic>{
        'addressId': 5,
        'remark': '尽快发货',
      });
    });

    test('备注未传时不携带 remark 字段', () async {
      final OrderService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': '20260101100001',
        });
      });

      await service.createOrder(addressId: 5);

      // 空备注不下发字段，由后端按缺省值落库。
      expect(decodedJsonBody(capturedRequest()), <String, dynamic>{
        'addressId': 5,
      });
    });
  });

  group('订单动作接口', () {
    test('confirmReceipt POST /api/orders/{orderNo}/confirm', () async {
      final OrderService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': null,
        });
      });

      await service.confirmReceipt('20260101100001');

      final RequestOptions request = capturedRequest();
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/orders/20260101100001/confirm');
    });

    test('cancelOrder POST /api/orders/{orderNo}/cancel', () async {
      final OrderService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': null,
        });
      });

      await service.cancelOrder('20260101100001');

      final RequestOptions request = capturedRequest();
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/orders/20260101100001/cancel');
    });
  });

  test('业务失败时抛出带后端提示的 ApiException', () async {
    final OrderService service = buildService();
    when(adapter.fetch(any, any, any)).thenAnswer((_) async {
      return jsonResponseBody(<String, dynamic>{
        'code': 1004,
        'message': '订单不存在',
        'data': null,
      });
    });

    await expectLater(
      service.cancelOrder('20260101100001'),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.message,
          'message',
          '订单不存在',
        ),
      ),
    );
  });
}
