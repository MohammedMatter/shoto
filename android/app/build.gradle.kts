plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.shoto.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Permanent, and the one thing on this page that can never be changed
        // after the first upload: Play identifies an app by its applicationId
        // forever. Renaming it later is not an edit, it is a different app
        // with a different listing and none of the installs.
        applicationId = "com.shoto.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // local_auth_android pins androidx.biometric 1.1.0, which predates
    // Android 12's rework of BiometricPrompt. On 1.1.0 the prompt routes
    // class-2 (weak) biometrics through a legacy path, and face unlock — which
    // is class 2 on nearly every phone that has it — is the casualty: the
    // prompt comes up fingerprint-only even where a face is enrolled and the
    // app asked for BIOMETRIC_WEAK.
    //
    // Declaring a newer version here wins the conflict resolution against the
    // plugin's transitive 1.1.0 without forking the plugin. 1.2.0-alpha05 is
    // the last published release of this artifact and is API-compatible with
    // everything local_auth_android calls.
    //
    // Note this cannot conjure face unlock onto a phone whose skin implements
    // it outside the biometric framework (see BiometricAuthService) — there is
    // no sensor for the prompt to offer. It fixes the phones that do have one.
    implementation("androidx.biometric:biometric:1.2.0-alpha05")
}

flutter {
    source = "../.."
}
