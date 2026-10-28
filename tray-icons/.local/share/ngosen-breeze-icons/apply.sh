#!/bin/bash
# Copy the Breeze-style icons over Ngó Sen's monochrome tray icons.
# Runs as root; the pacman hook re-runs it after every fcitx5-ngosen install/upgrade.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
ROOT=${ROOT:-}   # for dry-run testing only

# Ngó Sen points at hicolor, but Plasma looks the icon up by name in breeze/breeze-dark
dirs=(usr/share/icons/hicolor/scalable/{apps,status}
      usr/share/icons/breeze{,-dark}/status/{22,24})
mtree=$(zcat "$ROOT"/var/lib/pacman/local/fcitx5-ngosen-*/mtree 2>/dev/null || true)

for d in "${dirs[@]}"; do
  for f in "$here"/icons/*.svg; do
    n=$(basename "$f"); t=$ROOT/$d/$n
    [[ -f $t ]] || continue
    # Still the file the package installed: keep it as the original for restore.sh
    sum=$(grep -F "./$d/$n " <<<"$mtree" | grep -o 'sha256digest=[0-9a-f]*' | cut -d= -f2 || true)
    if [[ -n $sum && $(sha256sum <"$t" | cut -d' ' -f1) == "$sum" ]]; then
      install -Dm644 "$t" "$here/orig/$d/$n"
    fi
    install -m644 "$f" "$t"
  done
done
