# 🏠 DreamHouse237 — Application Mobile Flutter

Application mobile Flutter pour la plateforme immobilière DreamHouse au Cameroun.

## 🚀 Installation rapide

### 1. Prérequis
- Flutter SDK ≥ 3.3.0
- Dart ≥ 3.3.0
- Android Studio ou VS Code

### 2. Cloner et configurer
```bash
# Copier le dossier lib/ dans ton projet
# Remplacer pubspec.yaml
# Créer le fichier .env à la racine

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Fichier .env (à la racine du projet)
```
API_URL=https://dreamhouse237.onrender.com
```

### 4. Lancer
```bash
flutter run
```

---

## 🗂️ Architecture (Feature-First)

```
lib/
├── main.dart
├── core/
│   ├── network/
│   │   ├── api_client.dart          # Dio + intercepteur JWT
│   │   ├── api_endpoints.dart       # Toutes les URLs
│   │   └── connectivity_service.dart
│   ├── router/
│   │   └── app_router.dart          # GoRouter + guards
│   ├── storage/
│   │   └── secure_storage.dart      # JWT stockage sécurisé
│   └── theme/
│       └── app_theme.dart           # Couleurs, styles, thème
│
├── features/
│   ├── auth/                        # Login, Register, Session
│   ├── splash/                      # Écran de démarrage
│   ├── home/                        # Accueil public
│   ├── catalogue/                   # Recherche + filtres
│   ├── detail/                      # Détail bien + commentaires
│   ├── profile/                     # Profil utilisateur
│   ├── owner/                       # Espace propriétaire
│   │   ├── data/
│   │   └── presentation/
│   │       └── publish/             # Publication 3 étapes
│   └── map/                         # Carte flutter_map
│
└── shared/
    └── widgets/                     # Composants réutilisables
```

---

## 🔐 Rôles & Navigation

| Rôle | Accueil | Catalogue | Profil | Publier | Mes biens |
|------|---------|-----------|--------|---------|-----------|
| Visiteur | ✅ | ✅ | ❌ | ❌ | ❌ |
| Client | ✅ | ✅ | ✅ | ❌ | ❌ |
| Propriétaire | ✅ (accueil2) | ✅ | ✅ | ✅ | ✅ |
| Agence | ✅ (accueil2) | ✅ | ✅ | ✅ | ✅ |

---

## 🌐 Microservices Backend

| Service | Préfixe URL | Fonctionnalité |
|---------|-------------|----------------|
| Auth | `/AUTHENTIFICATION/` | Login JWT |
| User | `/USER-SERVICE/` | Profil, inscription |
| Publication | `/PUBLICATION-SERVICE/` | Biens immobiliers |
| Commentary | `/COMMENTARY-SERVICE/` | Commentaires |
| Identity | `/IDENTITY-SERVICE/` | Vérification CNI |

---

## 📦 Packages principaux

| Package | Rôle |
|---------|------|
| `flutter_riverpod` | Gestion d'état |
| `go_router` | Navigation |
| `dio` | HTTP + intercepteurs JWT |
| `flutter_secure_storage` | Stockage sécurisé token |
| `flutter_map` | Cartes OpenStreetMap |
| `image_picker` | Upload photos |
| `cached_network_image` | Images optimisées |
| `url_launcher` | Lien WhatsApp |
| `shimmer` | Skeleton loading |

---

## ⚙️ Configuration requise

Voir **CONFIGURATION.md** pour :
- Permissions Android (AndroidManifest.xml)
- Permissions iOS (Info.plist)
- minSdk Android (21)
