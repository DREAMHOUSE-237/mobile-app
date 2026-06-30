# 🚀 Guide Build Release — DreamHouse Flutter

## 1. Prérequis

```bash
flutter doctor        # Vérifier que tout est OK
flutter pub get       # Installer les packages
```

---

## 2. Générer les icônes de l'app (Sprint 9 - US-038)

### 2a. Créer le logo
Place ton logo DreamHouse (fond teal #007B83) dans :
```
assets/images/logo.png              # 1024x1024 px minimum
assets/images/logo_foreground.png   # Version sans fond (pour adaptive icon Android)
```

### 2b. Générer toutes les tailles automatiquement
```bash
flutter pub run flutter_launcher_icons
```

Cela va générer les icônes dans :
- `android/app/src/main/res/mipmap-*/` (toutes les densités)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

---

## 3. Configurer le nom de l'app

### Android — `android/app/src/main/AndroidManifest.xml`
```xml
<application
    android:label="DreamHouse"
    android:icon="@mipmap/ic_launcher"
    android:roundIcon="@mipmap/ic_launcher_round"
    android:usesCleartextTraffic="true"
    ...>
```

### iOS — `ios/Runner/Info.plist`
```xml
<key>CFBundleDisplayName</key>
<string>DreamHouse</string>
```

---

## 4. Configurer la signature Android (release)

### 4a. Créer un keystore
```bash
keytool -genkey -v \
  -keystore dreamhouse.keystore \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias dreamhouse

# Mettre le fichier dreamhouse.keystore dans android/app/
```

### 4b. Créer `android/key.properties`
```properties
storePassword=TON_MOT_DE_PASSE_STORE
keyPassword=TON_MOT_DE_PASSE_KEY
keyAlias=dreamhouse
storeFile=dreamhouse.keystore
```

### 4c. Modifier `android/app/build.gradle.kts`
```kotlin
// En haut du fichier, AVANT android {}
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    defaultConfig {
        applicationId = "com.dreamhouse237.mobile"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

---

## 5. Lancer les tests

```bash
# Tous les tests
flutter test

# Avec coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Un test spécifique
flutter test test/auth/auth_repository_test.dart
flutter test test/bien/bien_model_test.dart
flutter test test/cache/cache_service_test.dart
flutter test test/auth/user_model_test.dart
```

### Générer les mocks Mockito (obligatoire avant flutter test)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 6. Build APK Release

### APK universel (compatible tous appareils)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### APK par architecture (plus léger)
```bash
flutter build apk --split-per-abi --release
# Output:
#   app-armeabi-v7a-release.apk  (anciens appareils)
#   app-arm64-v8a-release.apk    (appareils modernes ← recommandé)
#   app-x86_64-release.apk       (émulateurs)
```

### AAB (Android App Bundle — pour le Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## 7. Installer sur un appareil Android

```bash
# Via USB (debug activé sur l'appareil)
flutter install --release

# Via ADB directement
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 8. Optimisations release recommandées

### Activer Proguard (`android/app/proguard-rules.pro`)
```
-keep class com.dreamhouse237.** { *; }
-keep class io.flutter.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**
```

### Vérifier la taille de l'APK
```bash
flutter build apk --analyze-size --release
```

---

## 9. Checklist finale avant livraison

- [ ] `flutter test` passe sans erreur
- [ ] `.env` pointe vers l'URL de production
- [ ] Icônes générées avec `flutter_launcher_icons`
- [ ] Nom app "DreamHouse" dans AndroidManifest.xml
- [ ] Permissions Android ajoutées (voir CONFIGURATION.md)
- [ ] minSdk = 21 dans build.gradle.kts
- [ ] Keystore configuré et signé
- [ ] APK testé sur un vrai appareil Android
- [ ] `flutter build apk --release` sans warning critique

---

## 10. Taille APK estimée

| Composant | Taille approx. |
|-----------|---------------|
| Flutter engine | ~5 MB |
| Dart code compilé | ~2 MB |
| flutter_map + assets | ~3 MB |
| Images & ressources | ~1 MB |
| **Total estimé** | **~11 MB** |
