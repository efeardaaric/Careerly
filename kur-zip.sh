#!/bin/zsh
setopt NULL_GLOB
set -euo pipefail
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/Homebrew/bin:$HOME/.local/bin:$HOME/development/flutter/bin:$PATH"
DEST="$HOME/Desktop/Careerly"
cd "$DEST"

zips=("$HOME/Downloads"/genesis*.zip "$HOME/Downloads"/*genesis*.zip "$HOME/Downloads"/efe-ar*.zip "$DEST"/*.zip)
ZIP=""
for z in $zips; do
  [[ -f "$z" ]] || continue
  if [[ -z "$ZIP" || "$z" -nt "$ZIP" ]]; then ZIP="$z"; fi
done
if [[ -z "$ZIP" ]]; then
  echo "ZIP yok. https://cursor.com/codebase/efe-ar/genesis → Code → Download ZIP"
  exit 1
fi
echo "ZIP: $ZIP"
TMP=$(mktemp -d)
unzip -q "$ZIP" -d "$TMP"
INNER=$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | head -1)
rsync -a --delete \
  --exclude 'kur-zip.sh' --exclude 'BEKLE-ZIP-BURAYA.txt' --exclude '.DS_Store' \
  "${INNER:-$TMP}/" "$DEST"/
rm -rf "$TMP"
[[ -f pubspec.yaml ]] || { echo "pubspec.yaml yok"; exit 1; }
if [[ -d .git ]]; then
  git fetch origin 2>/dev/null || true
  git checkout cursor/ui-ux-polish-0a5f 2>/dev/null || git checkout cursor/phase-8-1-rc-fixes-0a5f 2>/dev/null || true
fi
flutter pub get
(cd ios && pod install) || flutter build ios --config-only || true
echo "OK → $DEST"
ls -la | head -30
