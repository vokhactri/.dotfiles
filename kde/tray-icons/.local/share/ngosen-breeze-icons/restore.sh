#!/bin/bash
# Put Ngó Sen's original icons back and remove the hook. Usage: sudo ./restore.sh
set -euo pipefail
ROOT=${ROOT:-}   # for dry-run testing only
[[ $EUID -eq 0 || -n $ROOT ]] || { echo "Must be run with sudo"; exit 1; }
dest=$ROOT/usr/local/share/ngosen-breeze-icons
[[ -d $dest/orig/usr ]] || { echo "No original icons in $dest/orig"; exit 1; }
(cd "$dest/orig" && find usr -name '*.svg' -print0) | while IFS= read -r -d '' f; do
  install -m644 "$dest/orig/$f" "$ROOT/$f"
done
rm -f "$ROOT/etc/pacman.d/hooks/ngosen-breeze-icons.hook"
rm -rf "$dest"
echo "Restored. To get the lotus icons back, turn them on in Ngó Sen Settings."
echo "Restart plasmashell (without sudo):  systemctl --user restart plasma-plasmashell"
