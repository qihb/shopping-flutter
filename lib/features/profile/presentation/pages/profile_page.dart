import 'package:flutter/material.dart';

import 'package:my_first_app/features/order/presentation/models/order_record.dart';
import 'package:my_first_app/features/order/presentation/pages/order_record_page.dart';
import 'package:my_first_app/features/profile/data/models/address_vo.dart';
import 'package:my_first_app/features/profile/presentation/models/profile_settings.dart';
import 'package:my_first_app/features/profile/presentation/models/user_profile_summary.dart';
import 'package:my_first_app/features/profile/presentation/pages/address_management_page.dart';

/// 我的页面。
///
/// 电商项目里这个页面通常会放个人信息、订单入口、收藏记录等内容。
/// 这一版先承接“订单查看”这条链路，后面再继续补个人信息和基础设置。
class ProfilePage extends StatelessWidget {
  final UserProfileSummary profile;
  final bool isLoggedIn;
  final List<AddressVO> addresses;
  final ProfileSettings settings;
  final List<OrderRecord> orders;
  final ValueChanged<OrderRecord>? onAdvanceOrderStatus;
  final Future<bool> Function(OrderRecord order)? onRepayOrder;
  final ValueChanged<bool>? onNotificationChanged;
  final ValueChanged<bool>? onBiometricUnlockChanged;
  final ValueChanged<bool>? onPriceAlertChanged;
  final VoidCallback? onLogin;
  final VoidCallback? onLogout;

  const ProfilePage({
    super.key,
    required this.profile,
    this.isLoggedIn = true,
    this.addresses = const <AddressVO>[],
    required this.settings,
    this.orders = const <OrderRecord>[],
    this.onAdvanceOrderStatus,
    this.onRepayOrder,
    this.onNotificationChanged,
    this.onBiometricUnlockChanged,
    this.onPriceAlertChanged,
    this.onLogin,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final OrderRecord? latestOrder = orders.isEmpty ? null : orders.first;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _ProfileHeaderCard(
            profile: profile,
            isLoggedIn: isLoggedIn,
            onLogin: onLogin,
          ),
          const SizedBox(height: 20),
          _OrderStatusOverview(
            orders: orders,
            onAdvanceOrderStatus: onAdvanceOrderStatus,
            onRepayOrder: onRepayOrder,
          ),
          const SizedBox(height: 20),
          Text('最近订单', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (latestOrder == null)
            _ProfileEmptyOrderCard()
          else
            _ProfileLatestOrderCard(order: latestOrder),
          const SizedBox(height: 20),
          _ProfileAddressSection(addresses: addresses),
          const SizedBox(height: 20),
          _ProfileSettingsSection(
            settings: settings,
            isLoggedIn: isLoggedIn,
            onNotificationChanged: onNotificationChanged,
            onBiometricUnlockChanged: onBiometricUnlockChanged,
            onPriceAlertChanged: onPriceAlertChanged,
            onLogout: onLogout,
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final UserProfileSummary profile;
  final bool isLoggedIn;
  final VoidCallback? onLogin;

  const _ProfileHeaderCard({
    required this.profile,
    required this.isLoggedIn,
    this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            child: isLoggedIn
                ? Text(
                    profile.displayName.substring(0, 1),
                    style: Theme.of(context).textTheme.titleLarge,
                  )
                : const Icon(Icons.person_outline),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoggedIn ? 'Hi, ${profile.displayName}' : 'Hi，访客',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                // 联系方式按“手机号 > 邮箱”的优先级展示，都没有时引导登录。
                if (isLoggedIn) ...<Widget>[
                  Text(
                    profile.phone.isNotEmpty
                        ? profile.phone
                        : profile.email.isNotEmpty
                            ? profile.email
                            : '暂无联系方式',
                  ),
                  const SizedBox(height: 6),
                  Text('会员等级 ${profile.memberLabel}'),
                ] else
                  Text('点击登录后可同步订单与购物车'),
                const SizedBox(height: 6),
                Text('默认地址 ${profile.defaultAddress}'),
              ],
            ),
          ),
        ],
      ),
    );

    if (isLoggedIn) {
      return card;
    }

    // 未登录时整张卡片可点击，直接进入登录页。
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey<String>('profile-login-entry'),
        borderRadius: BorderRadius.circular(24),
        onTap: onLogin,
        child: card,
      ),
    );
  }
}

class _OrderStatusOverview extends StatelessWidget {
  final List<OrderRecord> orders;
  final ValueChanged<OrderRecord>? onAdvanceOrderStatus;
  final Future<bool> Function(OrderRecord order)? onRepayOrder;

  const _OrderStatusOverview({
    required this.orders,
    this.onAdvanceOrderStatus,
    this.onRepayOrder,
  });

  void _openOrderRecordPage(BuildContext context, String statusLabel) {
    // 点击订单状态后，打开新的订单记录页面。
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OrderRecordPage(
          initialStatusLabel: statusLabel,
          onAdvanceOrderStatus: onAdvanceOrderStatus,
          onRepayOrder: onRepayOrder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_OrderStatusItem> statusItems = [
      _OrderStatusItem(
        label: OrderStatus.pendingPayment.label,
        count: orders
            .where((order) => order.status == OrderStatus.pendingPayment)
            .length,
      ),
      _OrderStatusItem(
        label: OrderStatus.pendingShipment.label,
        count: orders
            .where((order) => order.status == OrderStatus.pendingShipment)
            .length,
      ),
      _OrderStatusItem(
        label: OrderStatus.pendingDelivery.label,
        count: orders
            .where((order) => order.status == OrderStatus.pendingDelivery)
            .length,
      ),
      _OrderStatusItem(
        label: OrderStatus.completed.label,
        count: orders.where((order) => order.status == OrderStatus.completed).length,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('订单状态', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Row(
          children: statusItems.asMap().entries.map((entry) {
            final int index = entry.key;
            final _OrderStatusItem item = entry.value;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == statusItems.length - 1 ? 0 : 8,
                ),
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    key: ValueKey<String>('profile-order-status-${item.label}'),
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _openOrderRecordPage(context, item.label),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      child: Column(
                        children: [
                          Text(
                            item.label,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.count}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ProfileEmptyOrderCard extends StatelessWidget {
  const _ProfileEmptyOrderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '还没有订单记录，先去购物车完成一次下单吧',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ProfileLatestOrderCard extends StatelessWidget {
  final OrderRecord order;

  const _ProfileLatestOrderCard({required this.order});

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
            '订单状态',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(order.statusLabel, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Text(
            '订单编号 ${order.id}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '商品清单',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name),
                  Text(
                    '数量 x${item.quantity}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '合计 ${order.totalPriceLabel}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '地址 ${order.shippingAddressLabel}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ProfileSettingsSection extends StatelessWidget {
  final ProfileSettings settings;
  final bool isLoggedIn;
  final ValueChanged<bool>? onNotificationChanged;
  final ValueChanged<bool>? onBiometricUnlockChanged;
  final ValueChanged<bool>? onPriceAlertChanged;
  final VoidCallback? onLogout;

  const _ProfileSettingsSection({
    required this.settings,
    required this.isLoggedIn,
    this.onNotificationChanged,
    this.onBiometricUnlockChanged,
    this.onPriceAlertChanged,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('基础设置', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                SwitchListTile(
                  key: const ValueKey<String>('profile-setting-notification'),
                  title: Text(
                    '消息通知: ${settings.enableNotification ? '已开启' : '已关闭'}',
                  ),
                  subtitle: const Text('下单、发货和活动提醒会出现在这里'),
                  value: settings.enableNotification,
                  onChanged: onNotificationChanged,
                ),
                SwitchListTile(
                  key: const ValueKey<String>('profile-setting-biometric'),
                  title: Text(
                    '生物解锁: ${settings.enableBiometricUnlock ? '已开启' : '已关闭'}',
                  ),
                  subtitle: const Text('用于模拟常见账户安全设置'),
                  value: settings.enableBiometricUnlock,
                  onChanged: onBiometricUnlockChanged,
                ),
                SwitchListTile(
                  key: const ValueKey<String>('profile-setting-price-alert'),
                  title: Text(
                    '降价提醒: ${settings.enablePriceAlert ? '已开启' : '已关闭'}',
                  ),
                  subtitle: const Text('关注的商品有活动时会提醒'),
                  value: settings.enablePriceAlert,
                  onChanged: onPriceAlertChanged,
                ),
                // 只有登录后才展示退出登录入口。
                if (isLoggedIn)
                  ListTile(
                    key: const ValueKey<String>('profile-logout-entry'),
                    leading: const Icon(Icons.logout),
                    title: const Text('退出登录'),
                    onTap: onLogout,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAddressSection extends StatelessWidget {
  final List<AddressVO> addresses;

  const _ProfileAddressSection({required this.addresses});

  void _openAddressManagementPage(BuildContext context) {
    // 地址管理页自己 watch AddressNotifier 并直接操作服务端接口，
    // 这里只负责跳转，不再回传数据与回调。
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddressManagementPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AddressVO? defaultAddress = addresses.isEmpty
        ? null
        : addresses.firstWhere(
            (AddressVO address) => address.isDefault,
            orElse: () => addresses.first,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('地址管理', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            key: const ValueKey<String>('profile-address-manage-entry'),
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openAddressManagementPage(context),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '默认地址 ${defaultAddress?.fullAddress ?? '暂未设置'}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          defaultAddress == null
                              ? '后续可以在这里维护多个收货地址'
                              : '${defaultAddress.receiverName} ${defaultAddress.receiverPhone}',
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderStatusItem {
  final String label;
  final int count;

  const _OrderStatusItem({required this.label, required this.count});
}
