import 'package:flutter/material.dart';

/// 我的页面。
///
/// 电商项目里这个页面通常会放个人信息、订单入口、收藏记录等内容。
/// 当前先保留成空页面，方便后续按模块继续扩展。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          '我的内容建设中',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
