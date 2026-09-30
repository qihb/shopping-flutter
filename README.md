# my_first_app

这是一个生产级的 Flutter 电商应用项目，目标是交付一套可维护、可演进、可测试的电商业务系统。

项目当前已完成工程骨架与核心业务主链路搭建，重点包括：

- 基于 Dart 与 Flutter 的电商业务实现
- 清晰、可持续演进的项目结构
- 关键实现说明与迭代日志的沉淀
- 每次迭代可回顾"实现了什么"与"如何实现"

## 当前实现

目前项目已经具备这些核心内容：

- 应用启动入口已拆分为 `main.dart` 和 `bootstrap.dart`
- 已有应用根组件 `MyApp`
- 已有统一主题入口 `AppTheme`
- 已有首页 `HomePage`、分类页、商品详情页、购物车、订单与个人中心等业务模块
- 已接入环境配置体系与 Mock/真实双路径支付架构
- 已有基础的单元测试与 Widget 测试

## 项目结构

当前核心目录约定如下：

```text
lib/
  app/                应用级能力，例如主题、路由、应用外壳、配置
  core/               通用能力，例如 API 客户端
  features/           业务模块目录（home、category、cart、order、payment、profile）
  main.dart           应用入口
  bootstrap.dart      启动初始化逻辑
test/                 测试目录
docs/                 迭代日志与设计文档目录
AGENTS.md             工程规范与 AI 协作规则
```

## 开发原则

- 优先保证代码清晰、可运行、可分析
- 优先使用 Flutter 原生能力，不提前堆复杂架构
- 新语法、新组件、新依赖默认补充说明性注释
- 每次迭代同步记录当前实现与对应技术点

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

## 多环境启动与构建

当前项目通过 `--dart-define=APP_ENV=...` 选择环境配置。

- `dev`：开发环境，对应 `assets/config/dev.json`
- `staging`：预发/联调环境，对应 `assets/config/staging.json`
- `prod`：生产环境，对应 `assets/config/prod.json`

如果没有显式传入 `APP_ENV`，代码会默认回退到 `dev` 环境。

按环境启动：

```bash
flutter run --dart-define=APP_ENV=dev
flutter run --dart-define=APP_ENV=staging
flutter run --dart-define=APP_ENV=prod
```

按环境构建 Web：

```bash
flutter build web --release --dart-define=APP_ENV=dev
flutter build web --release --dart-define=APP_ENV=staging
flutter build web --release --dart-define=APP_ENV=prod
```

如果后续需要构建其他平台，可以保持同样的环境参数写法，只替换构建目标。例如：

```bash
flutter build apk --release --dart-define=APP_ENV=staging
```

这套命令的底层逻辑是：

1. Flutter 在构建或运行时接收 `APP_ENV`
2. 启动阶段读取 `APP_ENV`，并映射成项目内部的环境枚举
3. 再根据环境去加载对应的 JSON 配置文件
4. 最终把 `appName`、`apiBaseUrl`、`enableDebugTools` 等配置提供给应用使用

## 相关文档

- [Flutter 官方文档](https://docs.flutter.dev/)
- [Dart 官方文档](https://dart.dev/guides)

## 迭代记录

每次准备提交代码前，建议补一份迭代日志，记录：

- 当前新增或调整了哪些功能
- 这些功能对应了哪些 Flutter 技术点
- 当前项目进度处于什么阶段
- 下一个节点准备做什么

当前迭代日志可查看 `docs/iteration_logs/` 目录文档。
