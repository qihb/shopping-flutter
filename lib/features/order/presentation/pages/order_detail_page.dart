import 'package:flutter/material.dart';

import 'package:my_first_app/features/order/presentation/models/order_record.dart';

/// 订单详情页。
///
/// 它和订单记录页的区别是：
/// - 订单记录页更像“某个状态下的订单列表”
/// - 订单详情页更像“查看某一笔订单的完整信息”
class OrderDetailPage extends StatefulWidget {
  final OrderRecord order;
  final ValueChanged<OrderRecord>? onAdvanceOrderStatus;

  const OrderDetailPage({
    super.key,
    required this.order,
    this.onAdvanceOrderStatus,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late OrderRecord _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  void _handleAdvanceOrderStatus() {
    if (!_order.canAdvanceStatus) {
      return;
    }

    widget.onAdvanceOrderStatus?.call(_order);
    setState(() {
      _order = _order.advanceStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  '订单编号 ${_order.id}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text('状态 ${_order.statusLabel}'),
                const SizedBox(height: 8),
                Text('合计 ${_order.totalPriceLabel}'),
                const SizedBox(height: 8),
                Text('地址 ${_order.shippingAddressLabel}'),
                if (_order.canAdvanceStatus) ...[
                  const SizedBox(height: 12),
                  Text('下一步: ${_order.nextStatusLabel}'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('商品清单', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          ..._order.items.map(
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
                    item.name,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text('单价 ${item.priceLabel}'),
                  const SizedBox(height: 4),
                  Text('数量 x${item.quantity}'),
                  const SizedBox(height: 4),
                  Text('小计 ${item.totalPriceLabel}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '这里先把订单详情页做成一个清晰、可阅读的静态信息页，后续很适合继续补地址、支付方式、时间线和售后入口。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          if (_order.canAdvanceStatus && widget.onAdvanceOrderStatus != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              key: ValueKey<String>('order-detail-advance-${_order.id}'),
              onPressed: _handleAdvanceOrderStatus,
              child: Text('推进到${_order.nextStatusLabel}'),
            ),
          ],
        ],
      ),
    );
  }
}
