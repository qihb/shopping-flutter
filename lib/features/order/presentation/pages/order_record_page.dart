import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/features/order/application/order_notifier.dart';
import 'package:my_first_app/features/order/presentation/models/order_record.dart';
import 'package:my_first_app/features/order/presentation/pages/order_detail_page.dart';

/// 订单记录页。
///
/// 现在通过 `context.watch<OrderNotifier>()` 实时监听订单列表，
/// 不再依赖父组件传入静态的 `orders` props。
/// 这样当订单状态发生变化时（支付成功、状态推进），页面会自动重建。
class OrderRecordPage extends StatelessWidget {
  final String initialStatusLabel;
  final ValueChanged<OrderRecord>? onAdvanceOrderStatus;
  final Future<bool> Function(OrderRecord order)? onRepayOrder;

  const OrderRecordPage({
    super.key,
    required this.initialStatusLabel,
    this.onAdvanceOrderStatus,
    this.onRepayOrder,
  });

  @override
  Widget build(BuildContext context) {
    final OrderNotifier orderNotifier = context.watch<OrderNotifier>();

    final List<OrderRecord> filteredOrders = orderNotifier.orders
        .where((order) => order.statusLabel == initialStatusLabel)
        .toList(growable: false);

    void handleAdvanceStatus(OrderRecord order) =>
        onAdvanceOrderStatus?.call(order);

    Future<void> handleRepayOrder(OrderRecord order) async =>
        await onRepayOrder?.call(order);

    void openOrderDetail(OrderRecord order) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => OrderDetailPage(
            order: order,
            onAdvanceOrderStatus:
                onAdvanceOrderStatus == null ? null : (order) => handleAdvanceStatus(order),
            onRepayOrder: onRepayOrder,
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
              '当前筛选：$initialStatusLabel',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          if (filteredOrders.isEmpty)
            _OrderRecordEmptyState(statusLabel: initialStatusLabel)
          else
            ...filteredOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderRecordCard(
                  order: order,
                  onTap: () => openOrderDetail(order),
                  onAdvanceOrderStatus: onAdvanceOrderStatus == null
                      ? null
                      : () => handleAdvanceStatus(order),
                  onRepayOrder: onRepayOrder == null
                      ? null
                      : () => handleRepayOrder(order),
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
  final OrderRecord order;
  final VoidCallback onTap;
  final VoidCallback? onAdvanceOrderStatus;
  final VoidCallback? onRepayOrder;

  const _OrderRecordCard({
    required this.order,
    required this.onTap,
    this.onAdvanceOrderStatus,
    this.onRepayOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: ValueKey<String>('order-record-card-${order.id}'),
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '订单编号 ${order.id}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('订单状态 ${order.statusLabel}'),
              const SizedBox(height: 8),
              Text('合计 ${order.totalPriceLabel}'),
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
                  child: Text('${item.name} x${item.quantity}'),
                ),
              ),
              const SizedBox(height: 12),
              if (order.canAdvanceStatus) ...[
                Text(
                  '下一步: ${order.nextStatusLabel}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
              ],
              if (order.canAdvanceStatus && onAdvanceOrderStatus != null)
                FilledButton.tonal(
                  key: ValueKey<String>('order-advance-${order.id}'),
                  onPressed: onAdvanceOrderStatus,
                  child: Text('推进到${order.nextStatusLabel}'),
                ),
              if (order.status == OrderStatus.pendingPayment &&
                  onRepayOrder != null) ...[
                const SizedBox(height: 8),
                FilledButton(
                  key: ValueKey<String>('order-repay-${order.id}'),
                  onPressed: onRepayOrder,
                  child: const Text('继续支付'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
