import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/features/order/data/models/order_item_vo.dart';
import 'package:my_first_app/features/order/data/models/order_status.dart';
import 'package:my_first_app/features/order/data/models/order_vo.dart';

void main() {
  /// 一条完整的订单 JSON（与 spring-shop `OrderVO` 字段对齐）。
  Map<String, dynamic> fullOrderJson({
    Object? status = 2,
    Object? totalAmount = 89.0,
    Object? payAmount = 19.9,
  }) {
    return <String, dynamic>{
      'id': 1,
      'orderNo': '20260101100001',
      'totalAmount': totalAmount,
      'payAmount': payAmount,
      'status': status,
      'statusDesc': '待发货',
      'receiverName': 'Qi Hai Bing',
      'receiverPhone': '13800001234',
      'receiverAddress': '上海市上海市浦东新区张江高科',
      'remark': '尽快发货',
      'createTime': '2026-01-01 10:00:00',
      'payTime': '2026-01-01 10:05:00',
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

  group('OrderVO.fromJson', () {
    test('解析服务端全量字段与明细快照', () {
      final OrderVO order = OrderVO.fromJson(fullOrderJson());

      expect(order.id, 1);
      expect(order.orderNo, '20260101100001');
      expect(order.totalAmount, 89.0);
      expect(order.payAmount, 19.9);
      expect(order.status, OrderStatus.pendingShipment);
      expect(order.statusDesc, '待发货');
      expect(order.receiverName, 'Qi Hai Bing');
      expect(order.receiverPhone, '13800001234');
      expect(order.receiverAddress, '上海市上海市浦东新区张江高科');
      expect(order.remark, '尽快发货');
      expect(order.createTime, '2026-01-01 10:00:00');
      expect(order.payTime, '2026-01-01 10:05:00');
      expect(order.shipTime, '');
      expect(order.finishTime, '');
      expect(order.cancelTime, '');

      expect(order.items, hasLength(1));
      expect(order.items.first.productName, '夏季轻运动鞋');
      expect(order.items.first.skuId, 9001);
      expect(order.items.first.price, 89.0);
    });

    test('可选字段缺失时回退为空值与零金额', () {
      final OrderVO order = OrderVO.fromJson(<String, dynamic>{'id': 2});

      expect(order.id, 2);
      expect(order.orderNo, '');
      expect(order.totalAmount, 0);
      expect(order.payAmount, 0);
      // 缺失状态按「不识别的状态码」兜底处理。
      expect(order.status, OrderStatus.pendingPayment);
      expect(order.statusDesc, '');
      expect(order.receiverName, '');
      expect(order.receiverAddress, '');
      expect(order.items, isEmpty);
    });

    test('服务端新增的状态码兜底为待付款', () {
      final OrderVO order = OrderVO.fromJson(fullOrderJson(status: 99));

      expect(order.status, OrderStatus.pendingPayment);
    });
  });

  group('orderStatusFromCode', () {
    test('覆盖六种订单状态的映射', () {
      expect(orderStatusFromCode(1), OrderStatus.pendingPayment);
      expect(orderStatusFromCode(2), OrderStatus.pendingShipment);
      expect(orderStatusFromCode(3), OrderStatus.pendingDelivery);
      expect(orderStatusFromCode(4), OrderStatus.completed);
      expect(orderStatusFromCode(5), OrderStatus.cancelled);
      expect(orderStatusFromCode(6), OrderStatus.refunded);
    });

    test('未知状态码兜底为待付款（动作集合最保守）', () {
      expect(orderStatusFromCode(0), OrderStatus.pendingPayment);
      expect(orderStatusFromCode(-1), OrderStatus.pendingPayment);
    });
  });

  group('状态与动作入口', () {
    test('canPay 只对待付款开放', () {
      expect(OrderStatus.pendingPayment.canPay, isTrue);
      expect(OrderStatus.pendingShipment.canPay, isFalse);
      expect(OrderStatus.pendingDelivery.canPay, isFalse);
      expect(OrderStatus.completed.canPay, isFalse);
      expect(OrderStatus.cancelled.canPay, isFalse);
      expect(OrderStatus.refunded.canPay, isFalse);
    });

    test('canConfirmReceipt 只对待收货开放', () {
      expect(OrderStatus.pendingPayment.canConfirmReceipt, isFalse);
      expect(OrderStatus.pendingShipment.canConfirmReceipt, isFalse);
      expect(OrderStatus.pendingDelivery.canConfirmReceipt, isTrue);
      expect(OrderStatus.completed.canConfirmReceipt, isFalse);
      expect(OrderStatus.cancelled.canConfirmReceipt, isFalse);
      expect(OrderStatus.refunded.canConfirmReceipt, isFalse);
    });

    test('状态文案与后端 statusDesc 口径一致', () {
      expect(OrderStatus.pendingPayment.label, '待付款');
      expect(OrderStatus.pendingShipment.label, '待发货');
      expect(OrderStatus.pendingDelivery.label, '待收货');
      expect(OrderStatus.completed.label, '已完成');
      expect(OrderStatus.cancelled.label, '已取消');
      expect(OrderStatus.refunded.label, '已退款');
    });
  });

  group('金额展示口径', () {
    test('整数金额省略小数，非整数保留两位小数', () {
      final OrderVO order = OrderVO.fromJson(fullOrderJson());

      expect(order.totalAmountLabel, '¥89');
      expect(order.payAmountLabel, '¥19.90');
    });

    test('明细单价与小计共用同一金额口径', () {
      final OrderItemVO item = OrderItemVO.fromJson(<String, dynamic>{
        'productId': 201,
        'skuId': 9201,
        'productName': '轻弹跑鞋',
        'price': 299.0,
        'quantity': 2,
        'subtotal': 598.0,
      });

      expect(item.priceLabel, '¥299');
      expect(item.subtotalLabel, '¥598');
    });
  });
}
