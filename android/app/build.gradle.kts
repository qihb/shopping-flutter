plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.my_first_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.my_first_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Patrol 要求使用它的 JUnit Runner 来桥接 Dart 侧 integration_test 用例
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        // 每个用例前清空应用数据，保证 E2E 用例之间互不污染
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    testOptions {
        // 通过 Orchestrator 逐个拉起用例，配合 clearPackageData 实现用例隔离
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // AndroidX Test Orchestrator：与上面的 execution = "ANDROIDX_TEST_ORCHESTRATOR" 配套，
    // 逐用例拉起进程实现隔离；版本与 Patrol 官方 example 保持一致
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
