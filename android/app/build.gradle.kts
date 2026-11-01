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
        // One runner for every integration_test/patrol_ftl_*.dart target.
        // clearPackageData is not baked in. Test Lab passes it with
        // --use-orchestrator only when the target file has two patrolTests.
        // A second runDartTest in one process returns HTTP 500.
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
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

// Prod release must match the only Firebase Android app. Build types cannot
// set applicationId in AGP 9; the variant API can.
androidComponents {
    onVariants { variant ->
        val activeFlavor = resolvedFlavor ?: if (variant.buildType == "release") "prod" else "dev"
        if (activeFlavor == "prod") {
            variant.applicationId.set("com.belongonthespectrum.sanctuary")
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
    // Debug builds already link the patrol plugin. androidTest compiles
    // MainActivityTest against that same project.
    androidTestImplementation(project(":patrol"))
    // Local `connectedAndroidTest` (what `patrol test` runs). Test Lab
    // installs its own orchestrator when --use-orchestrator is set.
    // 1.5.0 breaks test isolation; stay on 1.5.1+.
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}

flutter {
    source = "../.."
}
