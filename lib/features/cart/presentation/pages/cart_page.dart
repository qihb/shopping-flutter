import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_first_app/features/auth/application/auth_notifier.dart';
import 'package:my_first_app/features/cart/application/cart_notifier.dart';
import 'package:my_first_app/features/cart/data/models/cart_item_vo.dart';

/// 购物车页（服务端化版本）。
///
/// 数据来自 `CartNotifier`，背后是 spring-shop 的购物车接口：
/// - 未登录：展示登录引导空态（购物车数据依赖登录态）
/// - 已登录：渲染服务端条目，勾选 / 数量 / 删除 / 全选 / 清空全部走服务端
///
/// 提交订单仍通过 `onOpenConfirmPage` 回调交由 `MainTabPage` 编排，
/// 去登录同理走 `onLogin` 回调，页面本身不做导航编排。
class CartPage extends StatelessWidget {
  final VoidCallback? onOpenConfirmPage;
  final VoidCallback? onLogin;

  const CartPage({super.key, this.onOpenConfirmPage, this.onLogin});

  @override
  Widget build(BuildContext context) {
    final CartNotifier cartNotifier = context.watch<CartNotifier>();
    final AuthNotifier authNotifier = context.watch<AuthNotifier>();

    if (!authNotifier.isAuthenticated) {
      return _buildGuestPlaceholder(context);
    }

    // 首次加载时整页展示加载态，后续变更走静默刷新避免列表闪烁。
    if (cartNotifier.isLoading && cartNotifier.isEmpty) {
      return const SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(height: 12),
              Text('购物车加载中...'),
            ],
          ),
        ),
      );
    }

    if (cartNotifier.isEmpty) {
      return _buildEmptyPlaceholder(context, cartNotifier);
    }

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context, cartNotifier),
          Expanded(child: _buildItemList(context, cartNotifier)),
          _buildBottomBar(context, cartNotifier),
        ],
      ),
    );
  }

  // ---------- 空态 ----------

  /// 未登录占位：购物车依赖服务端数据，游客态给出登录引导。
  Widget _buildGuestPlaceholder(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '登录后查看购物车',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '登录后即可同步你的购物车商品',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey<String>('cart-login-guide'),
              onPressed: onLogin,
              child: const Text('去登录'),
            ),
          ],
        ),
      ),
    );
  }

  /// 已登录但没有任何条目；接口加载失败时附带错误信息与重试入口。
  Widget _buildEmptyPlaceholder(BuildContext context, CartNotifier cartNotifier) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '购物车还是空的',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '先去首页挑一件喜欢的商品吧',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (cartNotifier.errorMessage != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  cartNotifier.errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.error),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => cartNotifier.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- 列表区 ----------

  Widget _buildHeader(BuildContext context, CartNotifier cartNotifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '购物车共 ${cartNotifier.totalQuantity} 件',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey<String>('cart-clear-all'),
            onPressed: () =>
                _runOperation(context, cartNotifier.clearCart()),
            child: const Text('清空购物车'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(BuildContext context, CartNotifier cartNotifier) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: cartNotifier.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final CartItemVO item = cartNotifier.items[index];

        return _CartItemCard(
          item: item,
          onToggleChecked: item.isSelectable
              ? () => _runOperation(
                  context,
                  cartNotifier.setItemChecked(
                    itemId: item.id,
                    checked: !item.checked,
                  ),
                )
              : null,
          onIncrease: item.isSelectable
              ? () => _runOperation(
                  context,
                  cartNotifier.updateQuantity(
                    itemId: item.id,
                    quantity: item.quantity + 1,
                  ),
                )
              : null,
          // 数量最低保留 1，减到 1 以下没有意义，直接禁用按钮。
          onDecrease: item.isSelectable && item.quantity > 1
              ? () => _runOperation(
                  context,
                  cartNotifier.updateQuantity(
                    itemId: item.id,
                    quantity: item.quantity - 1,
                  ),
                )
              : null,
          onRemove: () =>
              _runOperation(context, cartNotifier.removeItem(item.id)),
        );
      },
    );
  }

  // ---------- 结算区 ----------

  Widget _buildBottomBar(BuildContext context, CartNotifier cartNotifier) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final List<CartItemVO> selectableItems = cartNotifier.items
        .where((CartItemVO item) => item.isSelectable)
        .toList(growable: false);
    final bool allChecked = selectableItems.isNotEmpty &&
        selectableItems.every((CartItemVO item) => item.checked);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                key: const ValueKey<String>('cart-check-all'),
                value: allChecked,
                onChanged: (_) => _runOperation(
                  context,
                  cartNotifier.setAllChecked(checked: !allChecked),
                ),
              ),
              const Text('全选'),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '合计 ¥${_formatAmount(cartNotifier.checkedAmount)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '已勾选 ${cartNotifier.checkedQuantity} 件',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // 没有勾选任何有效条目时禁止提交订单。
          FilledButton(
            key: const ValueKey<String>('cart-submit-order'),
            onPressed:
                cartNotifier.checkedQuantity > 0 ? onOpenConfirmPage : null,
            child: const Text('提交订单'),
          ),
        ],
      ),
    );
  }

  // ---------- 操作 ----------

  /// 执行一次购物车操作：失败时用 `CartNotifier.errorMessage` 弹 SnackBar。
  Future<void> _runOperation(
    BuildContext context,
    Future<bool> operation,
  ) async {
    final bool didSucceed = await operation;

    if (didSucceed || !context.mounted) {
      return;
    }

    final CartNotifier cartNotifier = context.read<CartNotifier>();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(cartNotifier.errorMessage ?? '操作失败，请稍后重试'),
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

  /// 金额展示：整数省略小数位，非整数保留原值。
  static String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return '${amount.toInt()}';
    }
    return '$amount';
  }
}

/// 购物车条目卡片。
///
/// 失效条目整体置灰：禁止勾选与数量修改，只保留删除操作，
/// 并用失效原因说明为什么不能结算。
class _CartItemCard extends StatelessWidget {
  final CartItemVO item;
  final VoidCallback? onToggleChecked;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onToggleChecked,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      // 失效条目整体降透明度，视觉上与可结算条目区分开。
      opacity: item.isSelectable ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              key: ValueKey<String>('cart-check-${item.id}'),
              value: item.checked,
              onChanged:
                  onToggleChecked == null ? null : (_) => onToggleChecked!(),
            ),
            _buildImage(colorScheme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.specs.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.specs,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  if (!item.isSelectable)
                    Text(
                      item.invalidReason.isEmpty ? '商品已失效' : item.invalidReason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    )
                  else
                    Text(
                      '¥${CartPage._formatAmount(item.price)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 4),
                  _buildBottomRow(context, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 底部行：有效条目展示数量步进器 + 删除；失效条目只有删除。
  Widget _buildBottomRow(BuildContext context, ColorScheme colorScheme) {
    if (!item.isSelectable) {
      return Align(
        alignment: Alignment.centerRight,
        child: _buildDeleteButton(context),
      );
    }

    return Row(
      children: [
        IconButton(
          key: ValueKey<String>('cart-decrease-${item.id}'),
          onPressed: onDecrease,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('${item.quantity}', style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          key: ValueKey<String>('cart-increase-${item.id}'),
          onPressed: onIncrease,
          icon: const Icon(Icons.add_circle_outline),
        ),
        const Spacer(),
        _buildDeleteButton(context),
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return TextButton.icon(
      key: ValueKey<String>('cart-delete-${item.id}'),
      onPressed: onRemove,
      icon: const Icon(Icons.delete_outline),
      label: const Text('删除'),
    );
  }

  /// 条目商品图：空地址直接展示占位图标，网络图失败回退到同一个占位。
  Widget _buildImage(ColorScheme colorScheme) {
    if (item.productImage.isEmpty) {
      return _buildImagePlaceholder(colorScheme);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Image.network(
          item.productImage,
          fit: BoxFit.cover,
          errorBuilder: (_, Object error, StackTrace? stackTrace) =>
              _buildImagePlaceholder(colorScheme),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, size: 28, color: colorScheme.primary),
    );
  }
}
