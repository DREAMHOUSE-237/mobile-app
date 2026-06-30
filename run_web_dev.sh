#!/bin/bash
# Lance Flutter Web en contournant CORS pour le développement
# NE PAS utiliser en production

echo "🚀 Lancement DreamHouse Flutter Web (mode dev - CORS désactivé)"
echo "⚠️  Ce mode est UNIQUEMENT pour le développement local"
echo ""

flutter run -d chrome \
  --web-browser-flag="--disable-web-security" \
  --web-browser-flag="--user-data-dir=/tmp/chrome_dev_$(date +%s)" \
  --dart-define=API_URL=https://dreamhouse237.onrender.com

