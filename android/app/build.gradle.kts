import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin for Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.voicebubble"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Enable desugaring for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.voicebubble"
        minSdk = 24
        targetSdk = 36
        versionCode = 13
        versionName = "1.0.3"
    }

    // Signing configuration
    // To create a release build:
    // 1. Create a keystore: keytool -genkey -v -keystore voicebubble-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias voicebubble
    // 2. Create android/key.properties with:
    //    storePassword=<your-keystore-password>
    //    keyPassword=<your-key-password>
    //    keyAlias=voicebubble
    //    storeFile=<path-to-keystore>/voicebubble-release.jks
    
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use release signing if available, otherwise use debug
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            
            // Disable code shrinking for now to avoid R8 issues
            // You can enable this later after adding proper ProGuard rules
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
