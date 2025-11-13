#!/bin/bash
# AndroidCreate.sh: create a reusable Java Android project quickly
# Usage: ./AndroidCreate.sh ProjectName com.example.package [--build] [--install]

set -e

# -------------------------
# 1️⃣ Parse arguments
# -------------------------
PROJECT_NAME=$1
PACKAGE_NAME=$2
BUILD=false
INSTALL=false

if [[ -z "$PROJECT_NAME" || -z "$PACKAGE_NAME" ]]; then
  echo "Usage: $0 ProjectName com.example.package [--build] [--install]"
  exit 1
fi

for arg in "$@"; do
  case $arg in
  --build) BUILD=true ;;
  --install) INSTALL=true ;;
  esac
done

# -------------------------
# 2️⃣ Variables
# -------------------------
ROOT_DIR="$PWD/$PROJECT_NAME"
APP_DIR="$ROOT_DIR/app"
JAVA_DIR="$APP_DIR/src/main/java/$(echo $PACKAGE_NAME | tr '.' '/')"
RES_DIR="$APP_DIR/src/main/res/layout"

ANDROID_PLUGIN_VERSION="8.2.1"
GRADLE_VERSION="9.1"

# -------------------------
# 3️⃣ Create folders
# -------------------------
mkdir -p "$JAVA_DIR"
mkdir -p "$RES_DIR"

# -------------------------
# 4️⃣ Generate Gradle wrapper
# -------------------------
cd "$ROOT_DIR"
if [ ! -f "gradlew" ]; then
  echo "Generating Gradle wrapper..."
  gradle wrapper --gradle-version $GRADLE_VERSION
fi

# -------------------------
# 5️⃣ Create build.gradle files
# -------------------------

# settings.gradle
cat >"$ROOT_DIR/settings.gradle" <<EOL
rootProject.name = "$PROJECT_NAME"
include(":app")
EOL

# project-level build.gradle
cat >"$ROOT_DIR/build.gradle" <<EOL
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:$ANDROID_PLUGIN_VERSION"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
EOL

# app-level build.gradle
cat >"$APP_DIR/build.gradle" <<EOL
apply plugin: 'com.android.application'

android {
    compileSdk 33

    defaultConfig {
        applicationId "$PACKAGE_NAME"
        minSdk 24
        targetSdk 33
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
}
EOL

# AndroidManifest.xml
mkdir -p "$APP_DIR/src/main"
cat >"$APP_DIR/src/main/AndroidManifest.xml" <<EOL
<manifest package="$PACKAGE_NAME" xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:allowBackup="true"
        android:label="$PROJECT_NAME"
        android:supportsRtl="true">
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOL

# MainActivity.java
cat >"$JAVA_DIR/MainActivity.java" <<EOL
package $PACKAGE_NAME;

import android.os.Bundle;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView tv = new TextView(this);
        tv.setText("Hello, $PROJECT_NAME!");
        setContentView(tv);
    }
}
EOL

# activity_main.xml
cat >"$RES_DIR/activity_main.xml" <<EOL
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:orientation="vertical" android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center">

    <TextView
        android:text="Hello, $PROJECT_NAME!"
        android:textSize="24sp"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"/>
</LinearLayout>
EOL

# -------------------------
# 6️⃣ Build APK (optional)
# -------------------------
cd "$ROOT_DIR"

if $BUILD; then
  echo "Building APK..."
  ./gradlew assembleDebug
  echo "APK built at: $APP_DIR/build/outputs/apk/debug/app-debug.apk"
fi

# -------------------------
# 7️⃣ Install APK (optional)
# -------------------------
if $INSTALL; then
  echo "Installing APK on device..."
  adb install -r "$APP_DIR/build/outputs/apk/debug/app-debug.apk"
fi

echo "Project $PROJECT_NAME created successfully at $ROOT_DIR"
