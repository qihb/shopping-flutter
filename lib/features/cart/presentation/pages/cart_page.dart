import 'package:flutter/material.dart';

import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';

/// 购物车页。
///
/// 当前先实现“空购物车”和“基础商品列表”两种状态，
/// 这样商品详情页的“加入购物车”就有明确承接位置了。
class CartPage extends StatelessWidget {
  final List<CartItem> items;
  final ValueChanged<CartItem>? onIncreaseQuantity;
  final ValueChanged<CartItem>? onDecreaseQuantity;
  final VoidCallback? onSubmitOrder;

  const CartPage({
    super.key,
    this.items = const <CartItem>[],
    this.onIncreaseQuantity,
    this.onDecreaseQuantity,
    this.onSubmitOrder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('购物车还是空的', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '先去首页挑一件喜欢的商品吧',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final int totalPrice = items.fold<int>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemBuilder: (context, index) {
                final CartItem item = items[index];

                return _CartItemCard(
                  item: item,
                  onIncreaseQuantity: onIncreaseQuantity,
                  onDecreaseQuantity: onDecreaseQuantity,
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemCount: items.length,
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '合计 EUR $totalPrice',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: onSubmitOrder,
                  child: const Text('提交订单'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<CartItem>? onIncreaseQuantity;
  final ValueChanged<CartItem>? onDecreaseQuantity;

  const _CartItemCard({
    required this.item,
    this.onIncreaseQuantity,
    this.onDecreaseQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.shopping_bag_outlined,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.priceLabel,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '数量 x${item.quantity}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      key: ValueKey<String>('cart-decrease-${item.name}'),
                      onPressed: () => onDecreaseQuantity?.call(item),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${item.quantity}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      key: ValueKey<String>('cart-increase-${item.name}'),
                      onPressed: () => onIncreaseQuantity?.call(item),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
