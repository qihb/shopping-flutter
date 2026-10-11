import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/features/cart/application/cart_notifier.dart';
import 'package:my_first_app/features/cart/presentation/models/cart_item.dart';

/// 购物车页。
///
/// 现在直接从 `CartNotifier` 读取和操作数据，
/// 不再依赖父组件通过 props 传入。
/// 提交订单仍然通过 `onOpenConfirmPage` 回调交由 `MainTabPage` 编排。
class CartPage extends StatelessWidget {
  final VoidCallback? onOpenConfirmPage;

  const CartPage({super.key, this.onOpenConfirmPage});

  @override
  Widget build(BuildContext context) {
    final CartNotifier cartNotifier = context.watch<CartNotifier>();

    if (cartNotifier.isEmpty) {
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

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '购物车商品 ${cartNotifier.items.length} 件',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  key: const ValueKey<String>('cart-clear-all'),
                  onPressed: () => cartNotifier.clear(),
                  child: const Text('清空购物车'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemBuilder: (context, index) {
                final CartItem item = cartNotifier.items[index];

                return _CartItemCard(
                  item: item,
                  onIncrease: () => cartNotifier.increaseQuantity(item),
                  onDecrease: () => cartNotifier.decreaseQuantity(item),
                  onRemove: () => cartNotifier.removeItem(item),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemCount: cartNotifier.items.length,
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
                    '合计 ¥${cartNotifier.totalPrice}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton(
                  key: const ValueKey<String>('cart-submit-order'),
                  onPressed: onOpenConfirmPage,
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
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
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
                  item.totalPriceLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
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
                      onPressed: onDecrease,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${item.quantity}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      key: ValueKey<String>('cart-increase-${item.name}'),
                      onPressed: onIncrease,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      key: ValueKey<String>('cart-delete-${item.name}'),
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('删除'),
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
