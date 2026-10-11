import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/features/order/application/order_notifier.dart';
import 'package:my_first_app/features/order/data/models/order_status.dart';
import 'package:my_first_app/features/order/data/models/order_vo.dart';
import 'package:my_first_app/features/order/presentation/pages/order_detail_page.dart';

/// 订单记录页。
///
/// 通过 `context.watch<OrderNotifier>()` 实时监听服务端订单列表，
/// 按 [initialStatus] 过滤出当前状态的订单。
/// 这样订单状态发生变化时（支付成功、确认收货、取消），页面会自动重建。
class OrderRecordPage extends StatelessWidget {
  final OrderStatus initialStatus;
  final Future<bool> Function(OrderVO order)? onRepayOrder;
  final Future<bool> Function(OrderVO order)? onConfirmOrder;
  final Future<bool> Function(OrderVO order)? onCancelOrder;

  const OrderRecordPage({
    super.key,
    required this.initialStatus,
    this.onRepayOrder,
    this.onConfirmOrder,
    this.onCancelOrder,
  });

  @override
  Widget build(BuildContext context) {
    final OrderNotifier orderNotifier = context.watch<OrderNotifier>();

    final List<OrderVO> filteredOrders = orderNotifier.orders
        .where((order) => order.status == initialStatus)
        .toList(growable: false);

    void openOrderDetail(OrderVO order) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => OrderDetailPage(
            order: order,
            onRepayOrder: onRepayOrder,
            onConfirmOrder: onConfirmOrder,
            onCancelOrder: onCancelOrder,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('订单记录')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '当前筛选：${initialStatus.label}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          if (filteredOrders.isEmpty)
            _OrderRecordEmptyState(statusLabel: initialStatus.label)
          else
            ...filteredOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderRecordCard(
                  order: order,
                  onTap: () => openOrderDetail(order),
                  onRepayOrder: onRepayOrder == null ? null : () => onRepayOrder!(order),
                  onConfirmOrder:
                      onConfirmOrder == null ? null : () => onConfirmOrder!(order),
                  onCancelOrder:
                      onCancelOrder == null ? null : () => onCancelOrder!(order),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderRecordEmptyState extends StatelessWidget {
  final String statusLabel;

  const _OrderRecordEmptyState({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '当前还没有$statusLabel的订单',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _OrderRecordCard extends StatelessWidget {
  final OrderVO order;
  final VoidCallback onTap;
  final VoidCallback? onRepayOrder;
  final VoidCallback? onConfirmOrder;
  final VoidCallback? onCancelOrder;

  const _OrderRecordCard({
    required this.order,
    required this.onTap,
    this.onRepayOrder,
    this.onConfirmOrder,
    this.onCancelOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: ValueKey<String>('order-record-card-${order.orderNo}'),
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '订单编号 ${order.orderNo}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('订单状态 ${order.statusLabel}'),
              const SizedBox(height: 8),
              Text('合计 ${order.payAmountLabel}'),
              const SizedBox(height: 12),
              Text(
                '商品清单',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${item.productName} x${item.quantity}'),
                ),
              ),
              const SizedBox(height: 12),
              // 动作按服务端状态机开放：待付款可继续支付 / 取消，待收货可确认收货。
              if (order.canPay && onRepayOrder != null)
                FilledButton(
                  key: ValueKey<String>('order-repay-${order.orderNo}'),
                  onPressed: onRepayOrder,
                  child: const Text('继续支付'),
                ),
              if (order.canPay && onCancelOrder != null) ...[
                const SizedBox(height: 8),
                FilledButton.tonal(
                  key: ValueKey<String>('order-cancel-${order.orderNo}'),
                  onPressed: onCancelOrder,
                  child: const Text('取消订单'),
                ),
              ],
              if (order.canConfirmReceipt && onConfirmOrder != null)
                FilledButton(
                  key: ValueKey<String>('order-confirm-${order.orderNo}'),
                  onPressed: onConfirmOrder,
                  child: const Text('确认收货'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
