/// 订单状态（对应后端 `OrderVO.status`）。
///
/// 使用 `enum` 统一订单状态，避免在页面里散落魔法数字，
/// 并为每个状态提供固定中文文案供列表、详情与筛选入口共用。
enum OrderStatus {
  pendingPayment,
  pendingShipment,
  pendingDelivery,
  completed,
  cancelled,
  refunded,
}

extension OrderStatusExtension on OrderStatus {
  /// 状态中文文案，与后端 statusDesc 的口径保持一致。
  String get label {
    switch (this) {
      case OrderStatus.pendingPayment:
        return '待付款';
      case OrderStatus.pendingShipment:
        return '待发货';
      case OrderStatus.pendingDelivery:
        return '待收货';
      case OrderStatus.completed:
        return '已完成';
      case OrderStatus.cancelled:
        return '已取消';
      case OrderStatus.refunded:
        return '已退款';
    }
  }

  /// 是否待付款（继续支付 / 取消订单两个动作只对该状态开放）。
  bool get canPay => this == OrderStatus.pendingPayment;

  /// 是否待收货（确认收货动作只对该状态开放）。
  bool get canConfirmReceipt => this == OrderStatus.pendingDelivery;
}

/// 订单状态解析与兜底。
///
/// 解析函数单独放在顶层而不是混入枚举扩展，
/// 让「状态码 → 枚举」的映射规则一处可查。
OrderStatus orderStatusFromCode(int code) {
  switch (code) {
    case 1:
      return OrderStatus.pendingPayment;
    case 2:
      return OrderStatus.pendingShipment;
    case 3:
      return OrderStatus.pendingDelivery;
    case 4:
      return OrderStatus.completed;
    case 5:
      return OrderStatus.cancelled;
    case 6:
      return OrderStatus.refunded;
    default:
      // 服务端新增状态时旧版本 App 不识别，兜底为待付款：
      // 该状态的动作集合（继续支付 / 取消）最保守，不会误触发确认收货。
      return OrderStatus.pendingPayment;
  }
}
