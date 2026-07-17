import 'package:flutter/material.dart';

import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';
import 'package:my_first_app/features/profile/presentation/models/user_address.dart';

/// 订单确认页。
///
/// 它位于“购物车”和“订单生成”之间，
/// 作用可以先理解成网页结算页里的“最后确认信息”步骤。
class OrderConfirmPage extends StatelessWidget {
  final List<CartItem> items;
  final UserAddress address;
  final VoidCallback onConfirmPayment;

  const OrderConfirmPage({
    super.key,
    required this.items,
    required this.address,
    required this.onConfirmPayment,
  });

  @override
  Widget build(BuildContext context) {
    final int totalPrice = items.fold<int>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('订单确认')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _ConfirmSectionCard(
            title: '收货地址',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.recipientName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(address.phone),
                const SizedBox(height: 8),
                Text(address.fullAddress),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ConfirmSectionCard(
            title: '商品信息',
            child: Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.name)),
                          Text('x${item.quantity}'),
                          const SizedBox(width: 12),
                          Text(item.totalPriceLabel),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 16),
          _ConfirmSectionCard(
            title: '支付说明',
            child: Text(
              '当前学习阶段先把支付结果固定为成功，重点理解“确认订单 -> 生成订单”的页面承接。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '应付 EUR $totalPrice',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton(
                key: const ValueKey<String>('order-confirm-pay'),
                onPressed: onConfirmPayment,
                child: const Text('确认支付'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ConfirmSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
