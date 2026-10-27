import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// BUG-017 : signature release. android/key.properties (ignore par Git, voir
// android/.gitignore) donne storeFile, storePassword, keyAlias, keyPassword.
// Sans ce fichier, toute tache release echoue avec un message clair : jamais
// de signature silencieuse avec la cle debug. Exception explicite, reservee
// aux builds QA non publiables : -PallowDebugSigning=true.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val releaseKeyFields = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val missingReleaseKeyFields = releaseKeyFields.filter {
    keystoreProperties.getProperty(it).isNullOrBlank()
}
val hasReleaseKey = keystorePropertiesFile.exists() && missingReleaseKeyFields.isEmpty()
val allowDebugSigning = providers.gradleProperty("allowDebugSigning").orNull == "true"

android {
    namespace = "com.lilcmonsters.seamonsters"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.lilcmonsters.seamonsters"
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

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = when {
                hasReleaseKey -> signingConfigs.getByName("release")
                allowDebugSigning -> signingConfigs.getByName("debug")
                else -> null
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

// BUG-017 : bloque toute tache release sans cle de publication.
val releaseSigningProblem: String? = when {
    hasReleaseKey -> null
    allowDebugSigning -> null
    !keystorePropertiesFile.exists() ->
        "android/key.properties est absent."
    else ->
        "android/key.properties incomplet : manque " +
            missingReleaseKeyFields.joinToString(", ") + "."
}
if (allowDebugSigning && !hasReleaseKey) {
    logger.warn(
        "ATTENTION : release signe avec la cle DEBUG (-PallowDebugSigning=true). " +
            "Build QA uniquement, NON PUBLIABLE sur un store.",
    )
}
gradle.taskGraph.whenReady {
    val problem = releaseSigningProblem ?: return@whenReady
    val releaseTasks = allTasks.filter {
        it.project == project && it.name.contains("Release") &&
            (it.name.startsWith("assemble") || it.name.startsWith("bundle") ||
                it.name.startsWith("package") || it.name.startsWith("sign"))
    }
    if (releaseTasks.isNotEmpty()) {
        throw GradleException(
            "Signature release impossible : $problem\n" +
                "Creer android/key.properties (ignore par Git) avec storeFile, " +
                "storePassword, keyAlias, keyPassword.\n" +
                "Build QA non publiable seulement : ajouter -PallowDebugSigning=true " +
                "(flutter build appbundle -PallowDebugSigning=true, ou " +
                "./gradlew bundleRelease -PallowDebugSigning=true).",
        )
    }
}
