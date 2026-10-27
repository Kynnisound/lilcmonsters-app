#!/usr/bin/env bash
# BUG-022 : le build web ne doit rien charger depuis un CDN (CanvasKit,
# police de secours). A lancer apres
#   flutter build web --release --no-web-resources-cdn
set -euo pipefail
dir="${1:-build/web}"
fail=0
grep -q '"useLocalCanvasKit":true' "$dir/flutter_bootstrap.js" \
  || { echo "ECHEC : useLocalCanvasKit absent (build sans --no-web-resources-cdn ?)"; fail=1; }
test -f "$dir/assets/fonts/fallback/Roboto-Regular.ttf" \
  || { echo "ECHEC : police de secours assets/fonts/fallback/ absente"; fail=1; }
test -f "$dir/canvaskit/canvaskit.wasm" \
  || { echo "ECHEC : canvaskit/ absent"; fail=1; }
echo "Mentions gstatic/googleapis restantes (a expliquer) :"
rg -n -o -c "gstatic|googleapis" "$dir" || echo "  aucune"
exit $fail
