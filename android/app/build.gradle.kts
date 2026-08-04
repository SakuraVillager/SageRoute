import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 从 key.properties 加载项目专用签名配置（所有开发者共用同一 keystore，保证 SHA1 一致）
fun loadKeystoreProperties(): Properties? {
    val propsFile = rootProject.file("key.properties")
    if (!propsFile.exists()) {
        println("WARNING: key.properties not found at ${propsFile.absolutePath}, falling back to default debug keystore")
        return null
    }
    val props = Properties()
    propsFile.inputStream().use { props.load(it) }
    return props
}

val keystoreProps = loadKeystoreProperties()

android {
    namespace = "com.sageroute.sageroute"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sageroute.sageroute"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 项目专用签名配置：使用 android/app/keystore/sageroute-dev.jks
    // 所有开发者共享同一 keystore，确保高德 SHA1 指纹一致
    val projectSigningConfig = signingConfigs.create("project").apply {
        if (keystoreProps != null) {
            storeFile = rootProject.file(keystoreProps!!.getProperty("storeFile"))
            storePassword = keystoreProps!!.getProperty("storePassword")
            keyAlias = keystoreProps!!.getProperty("keyAlias")
            keyPassword = keystoreProps!!.getProperty("keyPassword")
        }
    }

    buildTypes {
        debug {
            signingConfig = if (keystoreProps != null) projectSigningConfig else signingConfigs.getByName("debug")
        }
        release {
            signingConfig = if (keystoreProps != null) projectSigningConfig else signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 与 amap_map Flutter 插件使用同一统一 SDK，仅提供编译期可见性
    // （运行时已由 amap_map 的 implementation 依赖提供）
    compileOnly("com.amap.api:3dmap-location-search:10.1.200_loc6.4.9_sea9.7.4")
}
