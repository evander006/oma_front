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
        versionCode = 12
        versionName = "0.12.0-photo-pdf-fix"
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

dependencies {
    implementation("androidx.core:core:1.15.0")
    implementation("com.google.mlkit:image-labeling:17.0.9")
}
