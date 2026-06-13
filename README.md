# my_first_app

这是一个用于学习 Flutter 的电商网站项目。

项目当前处于工程骨架搭建和基础知识学习阶段，重点目标是：

- 用真实电商场景学习 Dart 和 Flutter
- 建立清晰、可持续演进的项目结构
- 在写功能的同时沉淀学习注释和阶段日志
- 让每次迭代都能回顾“实现了什么”和“学到了什么”

## 当前实现

目前项目已经具备这些基础内容：

- 应用启动入口已拆分为 `main.dart` 和 `bootstrap.dart`
- 已有应用根组件 `MyApp`
- 已有统一主题入口 `AppTheme`
- 已有首页骨架 `HomePage`
- 首页内容带有适合初学者理解的注释说明
- 已有基础 widget 测试

## 项目结构

当前核心目录约定如下：

```text
lib/
  app/                应用级能力，例如主题、路由、应用外壳
  features/           业务模块目录
  main.dart           应用入口
  bootstrap.dart      启动初始化逻辑
test/                 测试目录
docs/                 学习记录与阶段日志目录
AGENTS.md             工程规范与 AI 协作规则
```

## 开发原则

- 优先保证代码清晰、可运行、可分析
- 优先使用 Flutter 原生能力，不提前堆复杂架构
- 新语法、新组件、新依赖默认补充中文学习注释
- 每次迭代尽量同步记录当前实现和对应知识点

详细规范请查看 [AGENTS.md](./AGENTS.md)。

## 常用命令

安装依赖：

```bash
flutter pub get
```

静态检查：

```bash
flutter analyze
```

运行测试：

```bash
flutter test
```

启动应用：

```bash
flutter run
```

## 学习资料

如果你想补基础，可以从这些官方资料开始：

- [Flutter 入门学习](https://docs.flutter.dev/get-started/learn-flutter)
- [编写第一个 Flutter 应用](https://docs.flutter.dev/get-started/codelab)
- [Flutter 学习资源汇总](https://docs.flutter.dev/reference/learning-resources)
- [Flutter 官方文档](https://docs.flutter.dev/)

## 迭代记录

每次准备提交代码前，建议补一份阶段日志，记录：

- 当前新增或调整了哪些功能
- 这些功能对应了哪些 Flutter 知识点
- 当前项目进度处于什么阶段
- 下一个节点准备做什么

当前阶段日志可查看后续新增的 `docs/` 目录文档。
