plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.mentalwellness.app"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.mentalwellness.app"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        
        // Add NDK configuration for TensorFlow Lite support
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
        
        // Add multiDexEnabled for large app support
        multiDexEnabled = true
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
            
            // Add proguard rules for release builds
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    
     packaging {
        resources {
            pickFirsts += listOf(
                "**/libtensorflowlite_jni.so",
                "**/libtensorflowlite_c.so", 
                "**/libtensorflowlite_flex.so",
                "**/libtensorflowlite_gpu_delegate_plugin.so",
                "**/libc++_shared.so",
                "**/libjsc.so"
            )
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt", 
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0"
            )
        }
    }
    
    // Add lint options to handle warnings
    lint {
        disable += listOf("InvalidPackage", "MissingTranslation")
        checkReleaseBuilds = false
        abortOnError = false
    }
}
flutter {
    source = "../.."
}

dependencies {
    // Your existing core dependencies
    implementation("androidx.core:core-ktx:1.12.0")  // Updated version
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")  // Updated version
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Add multidex support
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Add work manager for background tasks
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    
    // TensorFlow Lite - Use compatible versions that work together
    implementation("org.tensorflow:tensorflow-lite:2.14.0") // or latest


    
    // Optional but recommended: GPU, NNAPI, metadata support
    implementation("org.tensorflow:tensorflow-lite-gpu:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-select-tf-ops:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-metadata:0.4.4")

    


    // Google ML Kit dependencies for face and pose detection
    implementation("com.google.mlkit:face-detection:16.1.7")
    implementation("com.google.mlkit:pose-detection:18.0.0-beta5")
    implementation("com.google.mlkit:pose-detection-accurate:18.0.0-beta5")
    implementation("com.google.android.gms:play-services-mlkit-face-detection:17.1.0")
    
    // Firebase BOM for version management
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-storage")
    
    // Google Sign-In
    implementation("com.google.android.gms:play-services-auth:21.2.0")
    
    // Camera and image processing
    implementation("androidx.camera:camera-core:1.4.0")
    implementation("androidx.camera:camera-camera2:1.4.0")
    implementation("androidx.camera:camera-lifecycle:1.4.0")
    implementation("androidx.camera:camera-video:1.4.0")
    implementation("androidx.camera:camera-view:1.4.0")
    implementation("androidx.camera:camera-extensions:1.4.0")
    
    // Audio processing
    implementation("androidx.media3:media3-exoplayer:1.5.0")
    implementation("androidx.media3:media3-ui:1.5.0")

    
    // Bluetooth support
    implementation("androidx.bluetooth:bluetooth:1.0.0-alpha02")
    // ADD THIS LINE INSTEAD
    // ADD THIS LINE INSTEAD
    implementation("com.google.android.support:wearable:2.8.1")    
    
    // Health and sensors
    implementation("androidx.health.connect:connect-client:1.1.0-alpha08")
    
    

    
    // File operations
    implementation("androidx.documentfile:documentfile:1.0.1")
    
    // Network operations
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.retrofit2:converter-gson:2.11.0")
    
    // JSON processing
    implementation("com.google.code.gson:gson:2.11.0")
    
    // Image loading and caching
    implementation("com.github.bumptech.glide:glide:4.16.0")
    
    // Charts and animations
    implementation("com.github.PhilJay:MPAndroidChart:v3.1.0")
    
    // Local database
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    
    // Permissions
    implementation("com.karumi:dexter:6.2.3")
    
    // Testing dependencies
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
}