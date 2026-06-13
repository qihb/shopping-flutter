import 'package:flutter/material.dart';

/// 首页占位页面。
///
/// 这个页面现在的作用不是承载具体业务，而是先把页面骨架留出来，
/// 方便你后续逐步往里面添加真正的业务内容。
///
/// 你可以把它理解成：
/// - 当前应用打开后的默认首页
/// - 后续业务模块接入前的占位页
/// - 一个示范性的页面结构参考
///
/// 后面你如果要加列表、表单、接口请求、状态管理，
/// 可以直接从这个页面开始改，或者把内容继续拆到更细的组件文件里。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 顶部导航栏，一般用来放页面标题、返回按钮、操作按钮。
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('首页'),
      ),
      // 页面主体内容区域。
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            // 限制内容最大宽度，避免在大屏设备上文字铺得太宽。
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 页面主标题。
                Text(
                  '首页模块占位页',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                // 第一段说明：告诉你这个页面当前的定位。
                Text(
                  '这个页面是后续业务组件、页面分区和状态管理接入的起点。',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                // 第二段说明：提示后续可以继续扩展哪些内容。
                Text(
                  '你可以先保留这个应用骨架，再逐步补充路由、首页分区或真正的电商业务组件。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
