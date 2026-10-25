import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Decode --dart-define=FLAVOR=<dev|stg|qa|prod> and -t lib/main_<flavor>.dart
// so builds receive the matching applicationIdSuffix (.dev, .stg, .qa, or "")
// without breaking standard `flutter run` / `flutter build apk` invocations.
val dartDefines: Map<String, String> = project.findProperty("dart-defines")
    ?.toString()
    ?.split(",")
    ?.mapNotNull { encoded ->
        runCatching {
            String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
        }.getOrNull()
    }
    ?.associate { pair ->
        val idx = pair.indexOf('=')
        if (idx > 0) pair.substring(0, idx) to pair.substring(idx + 1) else pair to ""
    } ?: emptyMap()

val targetProp = project.findProperty("target")?.toString() ?: ""
val resolvedFlavor: String? = (dartDefines["FLAVOR"] ?: when {
    targetProp.endsWith("main_prod.dart") -> "prod"
    targetProp.endsWith("main_stg.dart") -> "stg"
    targetProp.endsWith("main_qa.dart") -> "qa"
    targetProp.endsWith("main_dev.dart") -> "dev"
    else -> null
})?.trim()?.lowercase()

fun suffixForFlavor(flavor: String): String = when (flavor) {
    "dev" -> ".dev"
    "stg" -> ".stg"
    "qa" -> ".qa"
    else -> ""
}

// Keep in sync with AppFlavor.launcherTitle in lib/src/core/config/app_flavor.dart
fun appLabelForFlavor(flavor: String): String = when (flavor) {
    "dev" -> "[DEV] Belong on the Spectrum"
    "stg" -> "[STG] Belong on the Spectrum"
    "qa" -> "[QA] Belong on the Spectrum"
    else -> "Belong on the Spectrum"
}

android {
    namespace = "com.belongonthespectrum.refuge"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.belongonthespectrum.refuge"
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appName"] = "Belong on the Spectrum"
    }

    buildTypes {
        debug {
            val activeFlavor = resolvedFlavor ?: "dev"
            val suffix = suffixForFlavor(activeFlavor)
            if (suffix.isNotEmpty()) {
                applicationIdSuffix = suffix
            }
            manifestPlaceholders["appName"] = appLabelForFlavor(activeFlavor)
        }
        release {
            val activeFlavor = resolvedFlavor ?: "prod"
            val suffix = suffixForFlavor(activeFlavor)
            if (suffix.isNotEmpty()) {
                applicationIdSuffix = suffix
            }
            manifestPlaceholders["appName"] = appLabelForFlavor(activeFlavor)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
