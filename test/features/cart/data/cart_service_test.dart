import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/cart/data/cart_service.dart';
import '../../../helpers/http_body_helpers.dart';
import '../../../helpers/mocks.mocks.dart';

void main() {
  // 每个用例独立一套 ApiClient + Mock adapter，互不影响。
  late MockHttpClientAdapter adapter;

  CartService buildService() {
    adapter = MockHttpClientAdapter();
    final ApiClient apiClient = ApiClient(
      baseUrl: 'http://test.local',
      adapter: adapter,
    );
    return CartService(apiClient: apiClient);
  }

  RequestOptions capturedRequest() {
    return verify(adapter.fetch(captureAny, any, any)).captured.single
        as RequestOptions;
  }

  group('CartService.fetchCart', () {
    test('请求 /api/cart 并解析条目列表与服务端汇总', () async {
      final CartService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 1,
                'skuId': 9001,
                'productId': 3,
                'productName': '夏季轻运动鞋',
                'productImage': 'http://img.local/1.jpg',
                'specs': '白色 / 42 码',
                'price': 89,
                'originalPrice': 129,
                'quantity': 2,
                'checked': true,
                'stock': 50,
                'subtotal': 178,
                'invalid': false,
                'invalidReason': '',
              },
              <String, dynamic>{
                'id': 2,
                'skuId': 9002,
                'productId': 4,
                'productName': '下架商品',
                'productImage': '',
                'specs': '黑色',
                'price': 59,
                'originalPrice': 0,
                'quantity': 1,
                'checked': false,
                'stock': 0,
                'subtotal': 59,
                'invalid': true,
                'invalidReason': '商品已下架',
              },
            ],
            'totalQuantity': 3,
            'checkedQuantity': 2,
            'checkedAmount': 178,
          },
        });
      });

      final cart = await service.fetchCart();

      final RequestOptions request = capturedRequest();
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/cart');

      expect(cart.items, hasLength(2));
      expect(cart.totalQuantity, 3);
      expect(cart.checkedQuantity, 2);
      expect(cart.checkedAmount, 178);

      final first = cart.items.first;
      expect(first.id, 1);
      expect(first.skuId, 9001);
      expect(first.productId, 3);
      expect(first.productName, '夏季轻运动鞋');
      expect(first.productImage, 'http://img.local/1.jpg');
      expect(first.specs, '白色 / 42 码');
      expect(first.price, 89);
      expect(first.originalPrice, 129);
      expect(first.quantity, 2);
      expect(first.checked, isTrue);
      expect(first.stock, 50);
      expect(first.subtotal, 178);
      expect(first.invalid, isFalse);
      expect(first.isSelectable, isTrue);

      final invalidItem = cart.items.last;
      expect(invalidItem.invalid, isTrue);
      expect(invalidItem.invalidReason, '商品已下架');
      expect(invalidItem.isSelectable, isFalse);
    });
  });

  group('CartService.addItem', () {
    test('POST /api/cart/items，请求体携带 skuId 与 quantity', () async {
      final CartService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': null,
        });
      });

      await service.addItem(skuId: 9001, quantity: 2);

      final RequestOptions request = capturedRequest();
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/cart/items');
      expect(decodedJsonBody(request), <String, dynamic>{
        'skuId': 9001,
        'quantity': 2,
      });
    });

    test('quantity 未传时默认为 1', () async {
      final CartService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': null,
        });
      });

      await service.addItem(skuId: 9001);

      expect(decodedJsonBody(capturedRequest())['quantity'], 1);
    });
  });

  group('CartService.updateQuantity', () {
    test('PUT /api/cart/items/{id}，请求体携带新数量', () async {
      final CartService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': null,
        });
      });

      await service.updateQuantity(itemId: 5, quantity: 3);

      final RequestOptions request = capturedRequest();
      expect(request.method, 'PUT');
      expect(request.uri.path, '/api/cart/items/5');
      expect(decodedJsonBody(request), <String, dynamic>{'quantity': 3});
    });
  });

  group('CartService.removeItem', () {
    test('DELETE /api/cart/items/{id}', () async {
      final CartService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': null,
        });
      });

      await service.removeItem(5);

      final RequestOptions request = capturedRequest();
      expect(request.method, 'DELETE');
      expect(request.uri.path, '/api/cart/items/5');
    });
  });

  group('CartService.setItemChecked', () {
    test('PUT /api/cart/items/{id}/checked，请求体携带勾选状态', () async {
      final CartService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': null,
        });
      });

      await service.setItemChecked(itemId: 5, checked: true);

      final RequestOptions request = capturedRequest();
      expect(request.method, 'PUT');
      expect(request.uri.path, '/api/cart/items/5/checked');
      expect(decodedJsonBody(request), <String, dynamic>{'checked': true});
    });
  });

  group('CartService.setAllChecked', () {
    test('PUT /api/cart/checked，请求体携带全选状态', () async {
      final CartService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': null,
        });
      });

      await service.setAllChecked(checked: false);

      final RequestOptions request = capturedRequest();
      expect(request.method, 'PUT');
      expect(request.uri.path, '/api/cart/checked');
      expect(decodedJsonBody(request), <String, dynamic>{'checked': false});
    });
  });

  group('CartService.removeCheckedItems', () {
    test('DELETE /api/cart/checked', () async {
      final CartService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': null,
        });
      });

      await service.removeCheckedItems();

      final RequestOptions request = capturedRequest();
      expect(request.method, 'DELETE');
      expect(request.uri.path, '/api/cart/checked');
    });
  });

  group('CartService.clearCart', () {
    test('DELETE /api/cart', () async {
      final CartService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': null,
        });
      });

      await service.clearCart();

      final RequestOptions request = capturedRequest();
      expect(request.method, 'DELETE');
      expect(request.uri.path, '/api/cart');
    });
  });

  test('业务失败时抛出带后端提示的 ApiException', () async {
    final CartService service = buildService();
    when(adapter.fetch(any, any, any)).thenAnswer((_) async {
      return jsonResponseBody(<String, dynamic>{
        'code': 1004,
        'message': '购物车条目不存在',
        'data': null,
      });
    });

    await expectLater(
      service.updateQuantity(itemId: 5, quantity: 1),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.message,
          'message',
          '购物车条目不存在',
        ),
      ),
    );
  });
}
