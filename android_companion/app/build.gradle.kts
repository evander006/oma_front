plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}
android {
    namespace = "by.oma.companion"
    compileSdk = 35
    defaultConfig {
        applicationId = "by.oma.digitalhome.demo"
        minSdk = 26
        targetSdk = 35
        versionCode = 3
        versionName = "0.3.0-oma-auth-demo"
    }
    buildTypes {
        release { isMinifyEnabled = false }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}
