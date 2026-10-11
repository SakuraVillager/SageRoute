import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

fun isUsableKeystoreValue(value: String?): Boolean =
    !value.isNullOrBlank() &&
        !value.startsWith("REPLACE_WITH") &&
        !value.startsWith("<")

val keystoreStoreFile = keystoreProperties.getProperty("storeFile")
val keystoreStorePassword = keystoreProperties.getProperty("storePassword")
val keystoreKeyAlias = keystoreProperties.getProperty("keyAlias")
val keystoreKeyPassword = keystoreProperties.getProperty("keyPassword")

val hasValidDebugSigning = keystorePropertiesFile.exists() &&
    isUsableKeystoreValue(keystoreStoreFile) &&
    isUsableKeystoreValue(keystoreStorePassword) &&
    isUsableKeystoreValue(keystoreKeyAlias) &&
    isUsableKeystoreValue(keystoreKeyPassword) &&
    rootProject.file(keystoreStoreFile!!).isFile

android {
    namespace = "com.sageroute.sageroute"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

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

    // Use the shared team development certificate when android/key.properties
    // contains a valid, non-placeholder keystore. Keeping one certificate makes
    // AMap's SHA1 binding stable across developer machines. If the file is
    // missing or still contains placeholder values, fall back to the normal
    // Android debug keystore so `flutter run` works out of the box.
    if (hasValidDebugSigning) {
        signingConfigs {
            getByName("debug") {
                storeFile = rootProject.file(keystoreStoreFile!!)
                storePassword = keystoreStorePassword!!
                keyAlias = keystoreKeyAlias!!
                keyPassword = keystoreKeyPassword!!
            }
        }
    }

    buildTypes {
        release {
            // This is a team development certificate, not the production key.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 路径规划由 app 自己的 RoutePlanningHandler 调用搜索 SDK，因此这里必须
    // 是运行时依赖，不能依赖另一个 Flutter 插件间接把它带进 APK。
    implementation("com.amap.api:3dmap-location-search:10.1.200_loc6.4.9_sea9.7.4")
}
