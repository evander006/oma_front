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
        versionCode = 8
        versionName = "0.8.0-opengl-digital-twin"
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
