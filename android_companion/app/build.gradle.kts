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
        versionCode = 19
        versionName = "0.15.4-siglip-lan-preview"
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
    testImplementation("junit:junit:4.13.2")
}
