# 一次性脚本：按 Patrol 官方 SPM 集成步骤补齐 RunnerUITests target：
# 1) 把 FlutterGeneratedPluginSwiftPackage 加入 Frameworks（供 @import patrol 解析）
# 2) 添加 xcode_backend build / embed_and_thin 两个 Run Script 构建阶段
# 3) 关闭 User Script Sandboxing
# 运行方式（在 ios/ 目录下）：ruby add_uitests_spm.sh 或 ruby add_uitests_spm.rb
require 'xcodeproj'

project = Xcodeproj::Project.open(File.expand_path('Runner.xcodeproj', __dir__))
uitests = project.targets.find { |t| t.name == 'RunnerUITests' }
abort('RunnerUITests target not found') unless uitests

# --- 1. SPM 产品依赖：FlutterGeneratedPluginSwiftPackage ---
if uitests.package_product_dependencies.none? { |d| d.product_name == 'FlutterGeneratedPluginSwiftPackage' }
  product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product_dep.product_name = 'FlutterGeneratedPluginSwiftPackage'
  uitests.package_product_dependencies << product_dep
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = product_dep
  # SPM 产品依赖不是普通文件引用，需直接把 PBXBuildFile 放入 Frameworks 阶段
  uitests.frameworks_build_phase.files << build_file
  puts 'SPM package product added'
else
  puts 'SPM package product already present'
end

# --- 2. xcode_backend Run Script 构建阶段（顺序与官方文档、patrol e2e 工程一致）---
backend_scripts = {
  'xcode_backend build' => '/bin/sh "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" build',
  'xcode_backend embed_and_thin' => '/bin/sh "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" embed_and_thin',
}
backend_scripts.each do |name, script|
  next if uitests.build_phases.any? { |p| p.display_name == name }
  phase = project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
  phase.name = name
  phase.shell_script = script
  phase.show_env_vars_in_log = '0'
  uitests.build_phases << phase
end
# embed_and_thin 必须在 Sources/Frameworks/Resources 之后，build 必须在 Sources 之前
phases = uitests.build_phases
build_phase = phases.find { |p| p.display_name == 'xcode_backend build' }
uitests.build_phases.delete(build_phase)
uitests.build_phases.insert(phases.index(phases.find { |p| p.isa == 'PBXSourcesBuildPhase' }), build_phase)

# --- 3. 关闭 User Script Sandboxing（xcode_backend 需要访问 Flutter SDK 目录）---
uitests.build_configurations.each do |config|
  config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
end

project.save
puts 'RunnerUITests SPM setup done'
