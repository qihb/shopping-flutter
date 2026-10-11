import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/features/order/application/order_notifier.dart';
import 'package:my_first_app/features/order/data/models/order_vo.dart';

/// 订单详情页。
///
/// 它和订单记录页的区别是：
/// - 订单记录页更像“某个状态下的订单列表”
/// - 订单详情页更像“查看某一笔订单的完整信息”
///
/// 页面实时 watch [OrderNotifier]：动作触发服务端变更并刷新列表后，
/// 这里按 [OrderVO.orderNo] 重新定位最新订单数据，详情自动更新，
/// 不需要本地再维护一份可变状态。
class OrderDetailPage extends StatelessWidget {
  /// 打开详情时的订单快照，用于按订单号定位最新数据。
  final OrderVO order;
  final Future<bool> Function(OrderVO order)? onRepayOrder;
  final Future<bool> Function(OrderVO order)? onConfirmOrder;
  final Future<bool> Function(OrderVO order)? onCancelOrder;

  const OrderDetailPage({
    super.key,
    required this.order,
    this.onRepayOrder,
    this.onConfirmOrder,
    this.onCancelOrder,
  });

  @override
  Widget build(BuildContext context) {
    final OrderNotifier orderNotifier = context.watch<OrderNotifier>();

    // 列表刷新后按订单号取最新快照；订单被并发删除等极端情况下回退到入口快照。
    final OrderVO currentOrder = orderNotifier.orders.firstWhere(
      (candidate) => candidate.orderNo == order.orderNo,
      orElse: () => order,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('订单详情')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '订单编号 ${currentOrder.orderNo}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text('状态 ${currentOrder.statusLabel}'),
                const SizedBox(height: 8),
                Text('合计 ${currentOrder.payAmountLabel}'),
                const SizedBox(height: 8),
                Text('地址 ${currentOrder.receiverAddress}'),
                const SizedBox(height: 8),
                Text(
                  '收货人 ${currentOrder.receiverName} ${currentOrder.receiverPhone}',
                ),
                if (currentOrder.remark.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('备注 ${currentOrder.remark}'),
                ],
                if (currentOrder.createTime.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('下单时间 ${currentOrder.createTime}'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('商品清单', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          ...currentOrder.items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (item.skuSpecs.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('规格 ${item.skuSpecs}'),
                  ],
                  const SizedBox(height: 4),
                  Text('单价 ${item.priceLabel}'),
                  const SizedBox(height: 4),
                  Text('数量 x${item.quantity}'),
                  const SizedBox(height: 4),
                  Text('小计 ${item.subtotalLabel}'),
                ],
              ),
            ),
          ),
          // 动作按服务端状态机开放：待付款可继续支付 / 取消，待收货可确认收货。
          if (currentOrder.canPay && onRepayOrder != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              key: ValueKey<String>('order-detail-repay-${currentOrder.orderNo}'),
              onPressed: () => onRepayOrder!(currentOrder),
              child: const Text('继续支付'),
            ),
          ],
          if (currentOrder.canPay && onCancelOrder != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              key: ValueKey<String>('order-detail-cancel-${currentOrder.orderNo}'),
              onPressed: () => onCancelOrder!(currentOrder),
              child: const Text('取消订单'),
            ),
          ],
          if (currentOrder.canConfirmReceipt && onConfirmOrder != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              key: ValueKey<String>('order-detail-confirm-${currentOrder.orderNo}'),
              onPressed: () => onConfirmOrder!(currentOrder),
              child: const Text('确认收货'),
            ),
          ],
        ],
      ),
    );
  }
}
