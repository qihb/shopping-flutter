import 'package:flutter/foundation.dart';

import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';
import 'package:my_first_app/features/order/presentation/models/order_record.dart';
import 'package:my_first_app/features/payment/application/payment_service.dart';
import 'package:my_first_app/features/payment/data/models/payment_request.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_method.dart';
import 'package:my_first_app/features/payment/presentation/models/payment_result.dart';
import 'package:my_first_app/features/profile/presentation/models/user_address.dart';

/// 订单状态管理。
///
/// 它负责持有订单列表，并对外暴露下单、重新支付、推进状态等操作。
/// 支付动作依赖 `PaymentService`，通过构造函数注入。
class OrderNotifier extends ChangeNotifier {
  final PaymentService _paymentService;

  final List<OrderRecord> _orders = <OrderRecord>[];

  OrderNotifier({required PaymentService paymentService})
      : _paymentService = paymentService;

  /// 订单列表（不可变视图）。
  List<OrderRecord> get orders => List<OrderRecord>.unmodifiable(_orders);

  /// 用于展示的订单列表：真实订单为空时，返回学习示例数据。
  List<OrderRecord> get displayOrders =>
      _orders.isEmpty ? OrderRecord.learningSamples : orders;

  /// 提交新订单。
  ///
  /// 返回支付结果，调用方可据此决定 UI 反馈。
  /// 支付成功后订单状态自动推进到"待发货"。
  Future<PaymentResult> submitOrder({
    required List<CartItem> cartItems,
    required UserAddress shippingAddress,
    required PaymentMethod method,
  }) async {
    final String orderId =
        'ORD-${(_orders.length + 1).toString().padLeft(7, '0')}';
    final OrderRecord draftOrder = OrderRecord.fromCartItems(
      id: orderId,
      items: cartItems,
      shippingAddress: shippingAddress,
    );
    final PaymentResult paymentResult = await _paymentService.pay(
      PaymentRequest(
        orderId: orderId,
        amount: draftOrder.totalPrice,
        title: draftOrder.items.first.name,
        method: method,
      ),
    );
    final OrderRecord order = paymentResult.status == PaymentStatus.success
        ? draftOrder.advanceStatus()
        : draftOrder;

    _orders.insert(0, order);
    notifyListeners();

    return paymentResult;
  }

  /// 对已有订单重新支付。
  ///
  /// 返回 `true` 表示支付成功且状态已推进。
  Future<bool> repayOrder(OrderRecord order, PaymentMethod method) async {
    final int index = _orders.indexWhere((item) => item.id == order.id);

    if (index < 0) {
      return false;
    }

    final PaymentResult paymentResult = await _paymentService.pay(
      PaymentRequest(
        orderId: order.id,
        amount: order.totalPrice,
        title: order.items.first.name,
        method: method,
      ),
    );

    if (paymentResult.status == PaymentStatus.success) {
      _orders[index] = _orders[index].advanceStatus();
      notifyListeners();
    }

    return paymentResult.status == PaymentStatus.success;
  }

  /// 推进订单到下一状态。
  void advanceStatus(OrderRecord order) {
    final int index = _orders.indexWhere((item) => item.id == order.id);

    if (index < 0) {
      return;
    }

    final OrderRecord nextOrder = _orders[index].advanceStatus();

    if (identical(nextOrder, _orders[index])) {
      return;
    }

    _orders[index] = nextOrder;
    notifyListeners();
  }
}
