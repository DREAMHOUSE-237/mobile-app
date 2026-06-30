# 🖼️ Guide d'intégration du Logo DreamHouse

## Où déposer ton logo

```
dreamhouse237_mobile/
└── assets/
    └── images/
        ├── logo.png              ← TON LOGO PRINCIPAL (obligatoire)
        └── logo_foreground.png   ← Version sans fond pour Android (optionnel)
```

## Spécifications requises

| Fichier | Taille | Format | Usage |
|---------|--------|--------|-------|
| `logo.png` | **1024×1024 px minimum** | PNG | Splash, AppBar, Login, Footer |
| `logo_foreground.png` | 1024×1024 px, fond transparent | PNG | Icône adaptative Android |

## Étapes

### 1. Déposer le fichier
Copie ton logo dans `assets/images/logo.png`

### 2. Générer l'icône de l'app (optionnel)
```bash
flutter pub run flutter_launcher_icons
```
→ Génère automatiquement l'icône dans toutes les tailles Android/iOS

### 3. C'est tout !
Le logo apparaît automatiquement sur :
- ✅ Écran de démarrage (Splash Screen)
- ✅ Barre de navigation (AppBar) — Accueil & Espace proprio
- ✅ Écrans de connexion / inscription
- ✅ Footer de l'accueil

## Si tu n'as pas encore le logo
L'app fonctionne normalement — un fallback "D" teal est affiché partout.
