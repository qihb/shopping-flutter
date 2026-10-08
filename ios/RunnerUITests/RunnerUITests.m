// Patrol 的 iOS 测试入口。
// patrol_cli 会构建这个 UI Testing Bundle，并通过下面的宏把 Dart 侧
// integration_test 中的用例桥接为原生 XCTest 用例逐个执行。
// 该文件内容与 Patrol 官方 example 保持一致，勿手动添加用例。
@import XCTest;
@import patrol;
@import ObjectiveC.runtime;

#if !defined(PATROL_INTEGRATION_TEST_IOS_RUNNER)
#import "PatrolIntegrationTestIosRunner.h"
#endif

PATROL_INTEGRATION_TEST_IOS_RUNNER(RunnerUITests)
