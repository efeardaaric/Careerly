plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "ai.careerly.careerly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "ai.careerly.careerly"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    val hasReleaseKeystore = keystorePropertiesFile.exists()
    if (hasReleaseKeystore) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        if (hasReleaseKeystore) {
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
            // Store uploads require a real keystore (EXTERNAL ACTION).
            // Local `flutter run --release` may use debug signing unless
            // -PstoreRelease=true is set (then keystore is mandatory).
            val storeRelease = project.hasProperty("storeRelease") &&
                project.property("storeRelease").toString() == "true"
            if (storeRelease) {
                if (!hasReleaseKeystore) {
                    throw GradleException(
                        "EXTERNAL ACTION REQUIRED: create android/key.properties " +
                            "and a release keystore before storeRelease builds. " +
                            "Do not invent or commit signing secrets."
                    )
                }
                signingConfig = signingConfigs.getByName("release")
            } else if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Internal testing only — not for Play Store submission.
                signingConfig = signingConfigs.getByName("debug")
            }
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
