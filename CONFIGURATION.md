# Configuration Android & iOS — DreamHouse

## Android — AndroidManifest.xml
Ajoute ces permissions dans `android/app/src/main/AndroidManifest.xml`
AVANT la balise `<application>` :

```xml
<!-- Internet (API calls + flutter_map) -->
<uses-permission android:name="android.permission.INTERNET"/>

<!-- Galerie photos (image_picker) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

<!-- Caméra (image_picker optionnel) -->
<uses-permission android:name="android.permission.CAMERA"/>

<!-- WhatsApp / liens externes (url_launcher) -->
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"/>
```

DANS la balise `<application>` :
```xml
<application
    android:label="DreamHouse"
    android:usesCleartextTraffic="true"
    ...>
```

ET dans `<queries>` (pour url_launcher WhatsApp) :
```xml
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="https" />
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="http" />
    </intent>
    <package android:name="com.whatsapp" />
</queries>
```

## iOS — Info.plist
Ajoute dans `ios/Runner/Info.plist` :

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>DreamHouse a besoin d'accéder à votre galerie pour les photos de biens.</string>

<key>NSCameraUsageDescription</key>
<string>DreamHouse a besoin de la caméra pour prendre des photos de biens.</string>

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## build.gradle.kts — minSdk
Dans `android/app/build.gradle.kts` :
```kotlin
android {
    defaultConfig {
        minSdk = 21   // ← important pour flutter_secure_storage
        targetSdk = 34
    }
}
```
