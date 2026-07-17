import 'package:flutter/material.dart';

import 'package:my_first_app/features/order/presentation/models/order_record.dart';
import 'package:my_first_app/features/order/presentation/pages/order_detail_page.dart';

/// 订单记录页。
///
/// 这里单独拆一个页面，是为了让“我的”页里的订单状态入口
/// 能像真实电商应用一样，通过点击跳到更完整的订单列表。
class OrderRecordPage extends StatefulWidget {
  final List<OrderRecord> orders;
  final String initialStatusLabel;
  final ValueChanged<OrderRecord>? onAdvanceOrderStatus;

  const OrderRecordPage({
    super.key,
    required this.orders,
    required this.initialStatusLabel,
    this.onAdvanceOrderStatus,
  });

  @override
  State<OrderRecordPage> createState() => _OrderRecordPageState();
}

class _OrderRecordPageState extends State<OrderRecordPage> {
  List<OrderRecord> _buildFilteredOrders() {
    return widget.orders
        .where((order) => order.statusLabel == widget.initialStatusLabel)
        .toList(growable: false);
  }

  void _handleAdvanceOrderStatus(OrderRecord order) {
    widget.onAdvanceOrderStatus?.call(order);
    setState(() {});
  }

  void _openOrderDetail(OrderRecord order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OrderDetailPage(
          order: order,
          onAdvanceOrderStatus: widget.onAdvanceOrderStatus == null
              ? null
              : (targetOrder) {
                  widget.onAdvanceOrderStatus?.call(targetOrder);
                  setState(() {});
                },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<OrderRecord> filteredOrders = _buildFilteredOrders();

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
              '当前筛选：${widget.initialStatusLabel}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          if (filteredOrders.isEmpty)
            _OrderRecordEmptyState(statusLabel: widget.initialStatusLabel)
          else
            ...filteredOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderRecordCard(
                  order: order,
                  onTap: () => _openOrderDetail(order),
                  onAdvanceOrderStatus: widget.onAdvanceOrderStatus == null
                      ? null
                      : () => _handleAdvanceOrderStatus(order),
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

  const _OrderRecordCard({
    required this.order,
    required this.onTap,
    this.onAdvanceOrderStatus,
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
            ],
          ),
        ),
      ),
    );
  }
}
