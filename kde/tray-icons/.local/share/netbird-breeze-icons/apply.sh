#!/bin/bash
# Patch netbird-ui's tray icons to Breeze proportions.
# Runs as root; the pacman hook re-runs it after every netbird-ui install/upgrade.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
ROOT=${ROOT:-}   # for dry-run testing only
bin=$ROOT/usr/bin/netbird-ui
[[ -f $bin ]] || exit 0

# Still the file the package installed: keep it as the original for restore.sh
sum=$(zcat "$ROOT"/var/lib/pacman/local/netbird-ui*/mtree 2>/dev/null \
  | grep -F './usr/bin/netbird-ui ' | grep -o 'sha256digest=[0-9a-f]*' | cut -d= -f2 || true)
if [[ -n $sum && $(sha256sum <"$bin" | cut -d' ' -f1) == "$sum" ]]; then
  install -Dm755 "$bin" "$here/orig/netbird-ui"
fi
python3 -I "$here/patch.py" "$bin"
