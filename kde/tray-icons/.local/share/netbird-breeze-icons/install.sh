#!/bin/bash
# Install the netbird-ui tray icon patch and its pacman hook. Usage: sudo ./install.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
ROOT=${ROOT:-}   # for dry-run testing only
[[ $EUID -eq 0 || -n $ROOT ]] || { echo "Must be run with sudo"; exit 1; }
dest=$ROOT/usr/local/share/netbird-breeze-icons

install -Dm755 "$here/patch.py" "$dest/patch.py"
install -m755 "$here/apply.sh" "$dest/apply.sh"
install -Dm644 "$here/netbird-breeze-icons.hook" "$ROOT/etc/pacman.d/hooks/netbird-breeze-icons.hook"
ROOT=$ROOT "$dest/apply.sh"

echo "Done. Restart the NetBird UI (without sudo):"
echo "  pkill -x netbird-ui; setsid -f netbird-ui --daemon-addr unix:///var/run/netbird/main.sock >/dev/null 2>&1"
