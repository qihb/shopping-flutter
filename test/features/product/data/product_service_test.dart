import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:my_first_app/core/api/api_client.dart';
import 'package:my_first_app/core/api/api_exception.dart';
import 'package:my_first_app/features/product/data/models/category_node.dart';
import 'package:my_first_app/features/product/data/models/page_result.dart';
import 'package:my_first_app/features/product/data/models/product_detail.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';
import 'package:my_first_app/features/product/data/product_service.dart';
import '../../../helpers/http_body_helpers.dart';
import '../../../helpers/mocks.mocks.dart';

void main() {
  // 每个用例独立一套 ApiClient + Mock adapter，互不影响。
  late MockHttpClientAdapter adapter;

  ProductService buildService() {
    adapter = MockHttpClientAdapter();
    final ApiClient apiClient = ApiClient(
      baseUrl: 'http://test.local',
      adapter: adapter,
    );
    return ProductService(apiClient: apiClient);
  }

  RequestOptions capturedRequest() {
    return verify(adapter.fetch(captureAny, any, any)).captured.single
        as RequestOptions;
  }

  group('ProductService.fetchProducts', () {
    test('默认分页参数会拼 current/size，可选筛选不传时不拼', () async {
      final ProductService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <String, dynamic>{
            'records': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 1,
                'categoryId': 2,
                'categoryName': '服饰',
                'name': '夏季轻运动鞋',
                'subtitle': '透气网面设计',
                'mainImage': 'http://img.local/1.jpg',
                'minPrice': 89.5,
                'sales': 120,
                'status': 1,
                'createTime': '2026-01-01 10:00:00',
              },
            ],
            'total': 11,
            'pages': 2,
            'current': 1,
            'size': 10,
          },
        });
      });

      final PageResult<ProductSummary> page = await service.fetchProducts();

      final RequestOptions request = capturedRequest();
      expect(request.uri.path, '/api/products');
      expect(request.uri.queryParameters['current'], '1');
      expect(request.uri.queryParameters['size'], '10');
      expect(request.uri.queryParameters.containsKey('categoryId'), isFalse);
      expect(request.uri.queryParameters.containsKey('keyword'), isFalse);

      // Result<T> 解包 + JSON 到模型映射。
      expect(page.records, hasLength(1));
      expect(page.records.first.id, 1);
      expect(page.records.first.name, '夏季轻运动鞋');
      expect(page.records.first.categoryName, '服饰');
      expect(page.records.first.minPrice, 89.5);
      expect(page.records.first.sales, 120);
      expect(page.records.first.createTime, '2026-01-01 10:00:00');
      expect(page.total, 11);
      expect(page.pages, 2);
      expect(page.hasMore, isTrue);
    });

    test('传入 categoryId/keyword/current/size 时按值拼 query', () async {
      final ProductService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <String, dynamic>{
            'records': <dynamic>[],
            'total': 0,
            'pages': 0,
            'current': 2,
            'size': 5,
          },
        });
      });

      final PageResult<ProductSummary> page = await service.fetchProducts(
        categoryId: 5,
        keyword: '运动鞋',
        current: 2,
        size: 5,
      );

      final RequestOptions request = capturedRequest();
      expect(request.uri.queryParameters['categoryId'], '5');
      expect(request.uri.queryParameters['keyword'], '运动鞋');
      expect(request.uri.queryParameters['current'], '2');
      expect(request.uri.queryParameters['size'], '5');
      expect(page.records, isEmpty);
      // records 为空时即使 current < pages 也不该有下一页。
      expect(page.hasMore, isFalse);
    });

    test('业务失败时抛出带后端提示的 ApiException', () async {
      final ProductService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 500,
          'message': '服务器开小差了',
          'data': null,
        });
      });

      await expectLater(
        service.fetchProducts(),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.message,
            'message',
            '服务器开小差了',
          ),
        ),
      );
    });
  });

  group('ProductService.fetchProductDetail', () {
    test('按 id 拼路径并解析 SKU 与图片列表', () async {
      final ProductService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <String, dynamic>{
            'id': 3,
            'categoryId': 2,
            'categoryName': '服饰',
            'name': '夏季轻运动鞋',
            'subtitle': '透气网面设计',
            'mainImage': 'http://img.local/3.jpg',
            'detail': '<p>透气网面，适合通勤。</p>',
            'minPrice': 89,
            'sales': 120,
            'status': 1,
            'skus': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 9,
                'skuCode': 'SKU-009',
                'specs': '白色 / 42 码',
                'price': 89,
                'originalPrice': 129,
                'stock': 50,
                'status': 1,
              },
            ],
            'images': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 7,
                'imageUrl': 'http://img.local/3-1.png',
                'sort': 1,
              },
            ],
          },
        });
      });

      final ProductDetail detail = await service.fetchProductDetail(3);

      final RequestOptions request = capturedRequest();
      expect(request.uri.path, '/api/products/3');

      expect(detail.id, 3);
      expect(detail.name, '夏季轻运动鞋');
      expect(detail.detail, '<p>透气网面，适合通勤。</p>');
      expect(detail.minPrice, 89);
      expect(detail.skus, hasLength(1));
      expect(detail.skus.first.id, 9);
      expect(detail.skus.first.skuCode, 'SKU-009');
      expect(detail.skus.first.specs, '白色 / 42 码');
      expect(detail.skus.first.price, 89);
      expect(detail.skus.first.originalPrice, 129);
      expect(detail.skus.first.stock, 50);
      expect(detail.images, hasLength(1));
      expect(detail.images.first.imageUrl, 'http://img.local/3-1.png');
      expect(detail.images.first.sort, 1);
    });
  });

  group('ProductService.fetchCategoryTree', () {
    test('按树形结构递归解析分类节点', () async {
      final ProductService service = buildService();
      when(adapter.fetch(any, any, any)).thenAnswer((_) async {
        return jsonResponseBody(<String, dynamic>{
          'code': 200,
          'message': 'ok',
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'parentId': 0,
              'name': '服饰',
              'sort': 1,
              'status': 1,
              'children': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 11,
                  'parentId': 1,
                  'name': '男装',
                  'sort': 1,
                  'status': 1,
                  'children': <dynamic>[],
                },
              ],
            },
          ],
        });
      });

      final List<CategoryNode> tree = await service.fetchCategoryTree();

      final RequestOptions request = capturedRequest();
      expect(request.uri.path, '/api/categories/tree');

      expect(tree, hasLength(1));
      expect(tree.first.name, '服饰');
      expect(tree.first.hasChildren, isTrue);
      expect(tree.first.children.first.id, 11);
      expect(tree.first.children.first.name, '男装');
      expect(tree.first.children.first.parentId, 1);
      expect(tree.first.children.first.hasChildren, isFalse);
    });
  });
}
