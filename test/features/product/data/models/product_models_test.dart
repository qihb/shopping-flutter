import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/product/data/models/category_node.dart';
import 'package:my_first_app/features/product/data/models/page_result.dart';
import 'package:my_first_app/features/product/data/models/product_detail.dart';
import 'package:my_first_app/features/product/data/models/product_image.dart';
import 'package:my_first_app/features/product/data/models/product_sku.dart';
import 'package:my_first_app/features/product/data/models/product_summary.dart';

void main() {
  group('ProductSummary.fromJson', () {
    test('字段缺失时回退默认值', () {
      final ProductSummary product = ProductSummary.fromJson(
        <String, dynamic>{},
      );

      expect(product.id, 0);
      expect(product.categoryId, 0);
      expect(product.categoryName, '');
      expect(product.name, '');
      expect(product.subtitle, '');
      expect(product.mainImage, '');
      expect(product.minPrice, 0);
      expect(product.sales, 0);
      expect(product.status, 0);
      expect(product.createTime, '');
    });

    test('金额是整数时也会转成 double', () {
      final ProductSummary product = ProductSummary.fromJson(
        <String, dynamic>{'id': 1, 'name': '运动鞋', 'minPrice': 89},
      );

      expect(product.minPrice, isA<double>());
      expect(product.minPrice, 89.0);
    });
  });

  group('ProductSku.fromJson', () {
    test('字段缺失时回退默认值', () {
      final ProductSku sku = ProductSku.fromJson(<String, dynamic>{});

      expect(sku.id, 0);
      expect(sku.skuCode, '');
      expect(sku.specs, '');
      expect(sku.price, 0);
      expect(sku.originalPrice, 0);
      expect(sku.stock, 0);
      expect(sku.status, 0);
    });
  });

  group('ProductImage.fromJson', () {
    test('字段缺失时回退默认值', () {
      final ProductImage image = ProductImage.fromJson(<String, dynamic>{});

      expect(image.id, 0);
      expect(image.imageUrl, '');
      expect(image.sort, 0);
    });
  });

  group('ProductDetail.fromJson', () {
    test('skus/images 缺失时回退空列表', () {
      final ProductDetail detail = ProductDetail.fromJson(<String, dynamic>{
        'id': 3,
        'name': '夏季轻运动鞋',
      });

      expect(detail.id, 3);
      expect(detail.name, '夏季轻运动鞋');
      expect(detail.skus, isEmpty);
      expect(detail.images, isEmpty);
      expect(detail.detail, '');
      expect(detail.minPrice, 0);
    });
  });

  group('CategoryNode.fromJson', () {
    test('children 会递归解析出完整子树', () {
      final CategoryNode root = CategoryNode.fromJson(<String, dynamic>{
        'id': 1,
        'parentId': 0,
        'name': '服饰',
        'children': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 11,
            'parentId': 1,
            'name': '男装',
            'children': <Map<String, dynamic>>[
              <String, dynamic>{'id': 111, 'parentId': 11, 'name': 'T 恤'},
            ],
          },
        ],
      });

      expect(root.hasChildren, isTrue);
      expect(root.children.first.name, '男装');
      // 任意深度的节点都用同一套规则解析。
      expect(root.children.first.children.first.name, 'T 恤');
      expect(root.children.first.children.first.hasChildren, isFalse);
    });

    test('children 缺失时回退空列表', () {
      final CategoryNode node = CategoryNode.fromJson(<String, dynamic>{
        'id': 2,
        'name': '鞋靴',
      });

      expect(node.children, isEmpty);
      expect(node.hasChildren, isFalse);
    });
  });

  group('PageResult', () {
    ProductSummary itemFromJson(Map<String, dynamic> json) {
      return ProductSummary.fromJson(json);
    }

    test('records 会用 itemFromJson 逐条转换', () {
      final PageResult<ProductSummary> page = PageResult<ProductSummary>.fromJson(
        <String, dynamic>{
          'records': <Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'name': '夏季轻运动鞋'},
            <String, dynamic>{'id': 2, 'name': '极简双肩包'},
          ],
          'total': 2,
          'pages': 1,
          'current': 1,
          'size': 10,
        },
        itemFromJson,
      );

      expect(page.records, hasLength(2));
      expect(page.records.first, isA<ProductSummary>());
      expect(page.records.first.name, '夏季轻运动鞋');
      expect(page.total, 2);
      expect(page.size, 10);
      expect(page.hasMore, isFalse);
    });

    test('records 缺失时回退空列表', () {
      final PageResult<ProductSummary> page =
          PageResult<ProductSummary>.fromJson(
        <String, dynamic>{},
        itemFromJson,
      );

      expect(page.records, isEmpty);
      expect(page.total, 0);
      expect(page.hasMore, isFalse);
    });

    test('hasMore 边界：current 小于 pages 且有记录时为 true', () {
      final PageResult<ProductSummary> page = PageResult<ProductSummary>(
        records: const <ProductSummary>[],
        total: 0,
        pages: 0,
        current: 0,
        size: 0,
      );

      final PageResult<ProductSummary> withRecords =
          PageResult<ProductSummary>(
        records: <ProductSummary>[
          ProductSummary.fromJson(<String, dynamic>{'id': 1}),
        ],
        total: 11,
        pages: 2,
        current: 1,
        size: 10,
      );

      expect(page.hasMore, isFalse);
      expect(withRecords.hasMore, isTrue);
    });

    test('hasMore 边界：current 大于等于 pages 时为 false', () {
      final PageResult<ProductSummary> lastPage =
          PageResult<ProductSummary>.fromJson(
        <String, dynamic>{
          'records': <Map<String, dynamic>>[
            <String, dynamic>{'id': 1},
          ],
          'pages': 2,
          'current': 2,
        },
        itemFromJson,
      );

      final PageResult<ProductSummary> beyondPages =
          PageResult<ProductSummary>.fromJson(
        <String, dynamic>{
          'records': <Map<String, dynamic>>[
            <String, dynamic>{'id': 1},
          ],
          'pages': 1,
          'current': 3,
        },
        itemFromJson,
      );

      expect(lastPage.hasMore, isFalse);
      expect(beyondPages.hasMore, isFalse);
    });
  });
}
