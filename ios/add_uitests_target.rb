# 一次性脚本：向 Runner.xcodeproj 注入 Patrol 所需的 RunnerUITests target。
# 等价于在 Xcode 中手动新建一个 UI Testing Bundle target。
# 运行方式（在 ios/ 目录下）：ruby add_uitests_target.rb
require 'xcodeproj'

project = Xcodeproj::Project.open(File.expand_path('Runner.xcodeproj', __dir__))
runner = project.targets.find { |t| t.name == 'Runner' }
abort('Runner target not found') unless runner
abort('RunnerUITests target already exists') if project.targets.any? { |t| t.name == 'RunnerUITests' }

# 新建 UI Testing Bundle 类型 target（com.apple.product-type.bundle.ui-testing）
uitests = project.new_target(:ui_test_bundle, 'RunnerUITests', :ios, '13.0')

# 把 RunnerUITests.m 挂进工程文件树并加入编译阶段
group = project.main_group.new_group('RunnerUITests', 'RunnerUITests')
file_ref = group.new_file('RunnerUITests.m')
uitests.source_build_phase.add_file_reference(file_ref)

# 依赖 Runner，保证先构建宿主 App 再构建测试包
uitests.add_dependency(runner)

uitests.build_configurations.each do |config|
  # TEST_TARGET_NAME 声明该 UI 测试包作用的宿主 App，与 Podfile 中的 inherit! :complete 配套
  config.build_settings['TEST_TARGET_NAME'] = 'Runner'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.example.myFirstApp.RunnerUITests'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = 'D9BNSDSML8'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['SWIFT_VERSION'] = '5.0'
end

# 登记到工程 TargetAttributes，与 Xcode 手动创建时的元数据一致
attributes = project.root_object.attributes
attributes['TargetAttributes'] ||= {}
attributes['TargetAttributes'][uitests.uuid] = { 'TestTargetID' => runner.uuid }

project.save
puts 'RunnerUITests target created'
