# Platform setup

This repo contains `lib/`, `test/` and config. Generate the native folders once:

```bash
flutter create . --org com.yourcompany --project-name ayah --platforms android,ios
flutter pub get
flutter test
flutter run
```

`flutter create .` adds `android/` and `ios/` without touching `lib/`. Delete the generated
`test/widget_test.dart` (it references a counter app that doesn't exist).

## Android

`android/app/src/main/AndroidManifest.xml` — inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

Inside `<application>` (reminders survive reboot):

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

`LockCachingAudioSource` (offline audio cache) serves audio through a local proxy on
`127.0.0.1`. Allow cleartext for localhost only — add
`android:networkSecurityConfig="@xml/network_security_config"` to `<application>` and create
`android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">127.0.0.1</domain>
    </domain-config>
</network-security-config>
```

`android/app/build.gradle.kts` — flutter_local_notifications needs core library desugaring:

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

## iOS

`ios/Runner/Info.plist` — allow the local audio cache proxy:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

`ios/Runner/AppDelegate.swift` — so notifications show while the app is open:

```swift
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}
```

Set the deployment target to iOS 13+ in `ios/Podfile` (`platform :ios, '13.0'`).

## Fonts (before release)

Runtime font fetching works in development. For production (and fully offline first launch),
download **Amiri Quran** and **IBM Plex Sans Arabic** from Google Fonts into
`assets/google_fonts/`, declare the folder under `flutter: assets:` in `pubspec.yaml`, and set
`GoogleFonts.config.allowRuntimeFetching = false;` in `main()`.

## Verifying plugin APIs

Package versions in `pubspec.yaml` were pinned without network access to pub.dev. If
`flutter pub get` resolves a newer major version with API changes, the only files that touch
plugin APIs are in `lib/core/services/` — nothing else needs to change. The most likely spot is
`local_reminder_service.dart` (flutter_local_notifications changes `zonedSchedule` across majors).
