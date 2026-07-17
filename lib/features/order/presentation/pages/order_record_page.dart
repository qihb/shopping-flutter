import 'package:flutter/material.dart';

import 'package:my_first_app/features/order/presentation/models/order_record.dart';

/// 订单记录页。
///
/// 这里单独拆一个页面，是为了让“我的”页里的订单状态入口
/// 能像真实电商应用一样，通过点击跳到更完整的订单列表。
class OrderRecordPage extends StatelessWidget {
  final List<OrderRecord> orders;
  final String initialStatusLabel;

  const OrderRecordPage({
    super.key,
    required this.orders,
    required this.initialStatusLabel,
  });

  List<OrderRecord> _buildFilteredOrders() {
    return orders
        .where((order) => order.statusLabel == initialStatusLabel)
        .toList(growable: false);
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
                child: _OrderRecordCard(order: order),
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
        '当前还没有$statusLabel的订单，后续可以继续补充不同订单状态的流转。',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _OrderRecordCard extends StatelessWidget {
  final OrderRecord order;

  const _OrderRecordCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
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
        ],
      ),
    );
  }
}
