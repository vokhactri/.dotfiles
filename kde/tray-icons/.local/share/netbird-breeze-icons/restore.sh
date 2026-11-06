#!/bin/bash
# Put the original netbird-ui back and remove the hook. Usage: sudo ./restore.sh
set -euo pipefail
ROOT=${ROOT:-}   # for dry-run testing only
[[ $EUID -eq 0 || -n $ROOT ]] || { echo "Must be run with sudo"; exit 1; }
dest=$ROOT/usr/local/share/netbird-breeze-icons
[[ -f $dest/orig/netbird-ui ]] || { echo "No original binary in $dest/orig"; exit 1; }
install -m755 "$dest/orig/netbird-ui" "$ROOT/usr/bin/netbird-ui"
rm -f "$ROOT/etc/pacman.d/hooks/netbird-breeze-icons.hook"
rm -rf "$dest"
echo "Restored. Restart the NetBird UI (without sudo):"
echo "  pkill -x netbird-ui; setsid -f netbird-ui --daemon-addr unix:///var/run/netbird/main.sock >/dev/null 2>&1"
