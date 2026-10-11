import 'package:my_first_app/core/utils/amount_label.dart';
import 'package:my_first_app/features/order/data/models/order_item_vo.dart';
import 'package:my_first_app/features/order/data/models/order_status.dart';

/// 订单（对应后端 `OrderVO`，列表与详情共用）。
///
/// 收货信息与金额均为下单时快照：下单后修改地址、调价都不会
/// 影响已有订单，订单相关的所有展示以本模型字段为准。
class OrderVO {
  /// 订单 id（服务端主键），接口路径里的定位键是 [orderNo]。
  final int id;

  /// 订单号，支付 / 确认收货 / 取消等动作接口与 UI 唯一标识都用它。
  final String orderNo;

  /// 订单总金额（商品小计之和），单位：元。
  final double totalAmount;

  /// 实付金额（优惠后），单位：元。
  final double payAmount;

  /// 订单状态，见 [OrderStatus]。
  final OrderStatus status;

  /// 服务端下发的状态描述，保留备用；展示统一走 [statusLabel]。
  final String statusDesc;
  final String receiverName;
  final String receiverPhone;

  /// 收货地址快照（服务端已拼接省市区与详细地址）。
  final String receiverAddress;
  final String remark;
  final String createTime;
  final String payTime;
  final String shipTime;
  final String finishTime;
  final String cancelTime;
  final List<OrderItemVO> items;

  const OrderVO({
    required this.id,
    required this.orderNo,
    required this.totalAmount,
    required this.payAmount,
    required this.status,
    required this.statusDesc,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress,
    required this.remark,
    required this.createTime,
    required this.payTime,
    required this.shipTime,
    required this.finishTime,
    required this.cancelTime,
    required this.items,
  });

  factory OrderVO.fromJson(Map<String, dynamic> json) {
    return OrderVO(
      id: json['id'] as int? ?? 0,
      orderNo: json['orderNo'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      payAmount: (json['payAmount'] as num?)?.toDouble() ?? 0,
      status: orderStatusFromCode(json['status'] as int? ?? 0),
      statusDesc: json['statusDesc'] as String? ?? '',
      receiverName: json['receiverName'] as String? ?? '',
      receiverPhone: json['receiverPhone'] as String? ?? '',
      receiverAddress: json['receiverAddress'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
      createTime: json['createTime'] as String? ?? '',
      payTime: json['payTime'] as String? ?? '',
      shipTime: json['shipTime'] as String? ?? '',
      finishTime: json['finishTime'] as String? ?? '',
      cancelTime: json['cancelTime'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) =>
              OrderItemVO.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  String get statusLabel => status.label;

  /// 展示金额统一用实付口径，与结算页「应付」一致。
  String get payAmountLabel => '¥${amountLabel(payAmount)}';

  String get totalAmountLabel => '¥${amountLabel(totalAmount)}';

  /// 是否待付款（继续支付 / 取消订单入口的判断依据）。
  bool get canPay => status.canPay;

  /// 是否待收货（确认收货入口的判断依据）。
  bool get canConfirmReceipt => status.canConfirmReceipt;
}
