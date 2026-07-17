import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';
import 'package:my_first_app/features/profile/presentation/models/user_address.dart';

/// 订单状态。
///
/// 这里先用 `enum` 把订单状态收拢起来，
/// 这样比在页面里到处散落字符串更安全，也更适合后续继续补状态流转。
enum OrderStatus {
  pendingPayment,
  pendingShipment,
  pendingDelivery,
  completed,
}

extension OrderStatusExtension on OrderStatus {
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
    }
  }

  OrderStatus? get nextStatus {
    switch (this) {
      case OrderStatus.pendingPayment:
        return OrderStatus.pendingShipment;
      case OrderStatus.pendingShipment:
        return OrderStatus.pendingDelivery;
      case OrderStatus.pendingDelivery:
        return OrderStatus.completed;
      case OrderStatus.completed:
        return null;
    }
  }

  bool get canAdvance => nextStatus != null;
}

/// 订单记录。
///
/// 当前阶段先把订单做成一个轻量模型，
/// 目的是让购物车提交后，"我的" 页面有一份明确的数据可以展示。
class OrderRecord {
  static const List<OrderRecord> learningSamples = <OrderRecord>[
    OrderRecord(
      id: 'SAMPLE-1001',
      items: <CartItem>[
        CartItem(
          name: '轻弹跑鞋',
          priceLabel: 'EUR 299',
          unitPrice: 299,
        ),
      ],
      status: OrderStatus.pendingPayment,
      totalPrice: 299,
      shippingAddress: UserAddress(
        recipientName: 'Qi Hai Bing',
        phone: '138 0000 1234',
        cityLabel: '上海市',
        detailAddress: '浦东新区张江高科',
        isDefault: true,
      ),
    ),
    OrderRecord(
      id: 'SAMPLE-1002',
      items: <CartItem>[
        CartItem(
          name: '极简双肩包',
          priceLabel: 'EUR 129',
          unitPrice: 129,
        ),
        CartItem(
          name: '户外随行保温杯',
          priceLabel: 'EUR 49',
          unitPrice: 49,
        ),
      ],
      status: OrderStatus.pendingShipment,
      totalPrice: 178,
      shippingAddress: UserAddress(
        recipientName: 'Qi Hai Bing',
        phone: '138 0000 1234',
        cityLabel: '上海市',
        detailAddress: '徐汇区漕河泾开发区',
      ),
    ),
    OrderRecord(
      id: 'SAMPLE-1003',
      items: <CartItem>[
        CartItem(
          name: '香薰氛围灯',
          priceLabel: 'EUR 139',
          unitPrice: 139,
        ),
      ],
      status: OrderStatus.completed,
      totalPrice: 139,
      shippingAddress: UserAddress(
        recipientName: 'Qi Hai Bing',
        phone: '138 0000 1234',
        cityLabel: '上海市',
        detailAddress: '长宁区中山公园',
      ),
    ),
  ];

  final String id;
  final List<CartItem> items;
  final OrderStatus status;
  final int totalPrice;
  final UserAddress shippingAddress;

  const OrderRecord({
    required this.id,
    required this.items,
    required this.status,
    required this.totalPrice,
    required this.shippingAddress,
  });

  /// 这里先直接从购物车条目生成订单，
  /// 可以先把它理解成“下单时把当前购物车快照保存下来”。
  factory OrderRecord.fromCartItems({
    required String id,
    required List<CartItem> items,
    required UserAddress shippingAddress,
  }) {
    final List<CartItem> orderItems = items
        .map((item) => item.copyWith(quantity: item.quantity))
        .toList(growable: false);
    final int totalPrice = orderItems.fold<int>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    return OrderRecord(
      id: id,
      items: orderItems,
      status: OrderStatus.pendingShipment,
      totalPrice: totalPrice,
      shippingAddress: shippingAddress,
    );
  }

  String get statusLabel => status.label;

  String get totalPriceLabel => 'EUR $totalPrice';

  String get shippingAddressLabel => shippingAddress.fullAddress;

  String? get nextStatusLabel => status.nextStatus?.label;

  bool get canAdvanceStatus => status.canAdvance;

  OrderRecord copyWith({
    List<CartItem>? items,
    OrderStatus? status,
    int? totalPrice,
    UserAddress? shippingAddress,
  }) {
    return OrderRecord(
      id: id,
      items: items ?? this.items,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      shippingAddress: shippingAddress ?? this.shippingAddress,
    );
  }

  OrderRecord advanceStatus() {
    final OrderStatus? nextStatus = status.nextStatus;

    if (nextStatus == null) {
      return this;
    }

    return copyWith(status: nextStatus);
  }
}
