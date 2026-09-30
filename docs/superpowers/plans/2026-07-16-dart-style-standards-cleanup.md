# Dart Style Standards Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为当前 Flutter 项目补充一套团队级 Dart / Flutter 书写规范，并按同一套标准整理现有源码结构。

**Architecture:** 本次不改业务行为，只统一代码组织方式、类内成员顺序、`const` 使用和说明性注释的落点。整理范围以 `lib/` 下现有 Dart 源码为主，最后用格式化、`flutter analyze` 和 `flutter test` 验证整理结果。

**Tech Stack:** Dart、Flutter、Material 3、`dart format`、`flutter analyze`、`flutter test`

---

### Task 1: 补充团队级书写规范

**Files:**
- Modify: `AGENTS.md`
- Create: `docs/superpowers/plans/2026-07-16-dart-style-standards-cleanup.md`

- [ ] **Step 1: 明确新增规范的边界**

本次新增规范只覆盖当前项目最常见、最容易持续执行的内容：

```text
1. 类内成员顺序
2. Model 与 Widget 的常见写法
3. const / final 的使用原则
4. 说明性注释的落点
5. AI 生成代码后的复核要求
```

- [ ] **Step 2: 在 `AGENTS.md` 增补团队条目**

将以下核心内容补入“Dart 与 Flutter 编码规范”附近，便于后续统一遵守：

```text
- 普通数据类优先“字段在前，构造函数在后”
- Widget / State / Service / Store 明确成员顺序
- 静态常量、实例字段、构造函数、getter、生命周期、公共方法、私有方法保持固定顺序
- 生成代码后必须按这份顺序自检
```

- [ ] **Step 3: 保持规则语言适合当前项目**

新增条目要继续延续项目现有风格：

```text
- 面向 Flutter 开发者
- 强调为什么这样排更容易读
- 不引入过重、过学术化的规范术语
```

### Task 2: 按规范整理当前源码

**Files:**
- Modify: `lib/app/config/app_config.dart`
- Modify: `lib/app/config/app_config_loader.dart`
- Modify: `lib/features/cart/presentation/models/cart_item.dart`
- Modify: `lib/features/cart/presentation/pages/cart_page.dart`
- Modify: `lib/features/category/presentation/pages/category_page.dart`
- Modify: `lib/features/home/data/home_recommend_mock_service.dart`
- Modify: `lib/features/home/presentation/models/home_banner_item.dart`
- Modify: `lib/features/home/presentation/models/home_recommend_product.dart`
- Modify: `lib/features/home/presentation/pages/home_banner_detail_page.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart`
- Modify: `lib/features/home/presentation/pages/product_detail_page.dart`
- Modify: `lib/features/home/presentation/widgets/home_banner_carousel.dart`
- Modify: `lib/features/home/presentation/widgets/home_banner_media_artwork.dart`
- Modify: `lib/features/home/presentation/widgets/home_banner_video_player.dart`
- Modify: `lib/features/home/presentation/widgets/recommend_product_card.dart`
- Modify: `lib/features/order/presentation/models/order_record.dart`
- Modify: `lib/features/profile/presentation/models/profile_settings.dart`
- Modify: `lib/features/profile/presentation/models/user_profile_summary.dart`
- Modify: `lib/features/profile/presentation/pages/profile_page.dart`

- [ ] **Step 1: 先整理纯数据类**

统一 Model 类顺序：

```text
1. static const / static final
2. final 字段
3. const 构造函数 / factory
4. getter
5. copyWith / fromXxx / 解析辅助方法
```

- [ ] **Step 2: 再整理 Widget 类**

统一 Widget 类顺序：

```text
1. static const / static final
2. final 字段
3. const 构造函数
4. 生命周期方法（State 类）
5. 公开交互方法
6. 私有辅助方法
7. build()
```

- [ ] **Step 3: 补充可以自然使用的 `const`**

只在不改变行为、且确实提高可读性时补充，例如：

```dart
class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();
}
```

- [ ] **Step 4: 保持行为不变**

整理时禁止顺手改动这些内容：

```text
- 页面跳转逻辑
- 购物车与订单计算逻辑
- 配置加载行为
- 测试断言语义
```

### Task 3: 回归验证

**Files:**
- Verify: `lib/**/*.dart`
- Verify: `test/**/*.dart`

- [ ] **Step 1: 运行格式化**

Run:

```bash
dart format lib
```

Expected:

```text
所有整理过的 Dart 文件被统一格式化，缩进与换行风格保持一致。
```

- [ ] **Step 2: 运行静态检查**

Run:

```bash
flutter analyze
```

Expected:

```text
Analyze 通过，没有新增 warning / error。
```

- [ ] **Step 3: 运行测试**

Run:

```bash
flutter test
```

Expected:

```text
现有测试继续通过，证明本次整理没有改坏已有行为。
```
