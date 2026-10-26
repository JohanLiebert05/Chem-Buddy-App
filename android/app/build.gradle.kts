plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val previewBuild = System.getenv("CHEMBUDDY_PREVIEW_BUILD") == "true"

android {
    namespace = "com.chembuddy.chem_buddy"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        resValues = true
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = if (previewBuild) "com.chembuddy.chem_buddy.preview" else "com.chembuddy.chem_buddy"
        resValue("string", "app_name", if (previewBuild) "ChemBuddy Preview" else "ChemBuddy")
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystorePath = System.getenv("CHEMBUDDY_KEYSTORE_PATH")
    signingConfigs {
        if (!keystorePath.isNullOrBlank()) {
            create("production") {
                storeFile = file(keystorePath)
                storePassword = System.getenv("CHEMBUDDY_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("CHEMBUDDY_KEY_ALIAS")
                keyPassword = System.getenv("CHEMBUDDY_KEY_PASSWORD")
            }
        }
    }
    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = if (previewBuild) signingConfigs.getByName("debug") else signingConfigs.findByName("production")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
