#!/bin/bash
# Install Breeze-style tray icons for Ngó Sen. Usage: sudo ./install.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
ROOT=${ROOT:-}   # for dry-run testing only
[[ $EUID -eq 0 || -n $ROOT ]] || { echo "Must be run with sudo"; exit 1; }
owner=${SUDO_USER:-$(id -un "${PKEXEC_UID:-0}")}
dest=$ROOT/usr/local/share/ngosen-breeze-icons

install -d "$dest/icons"
install -m644 "$here"/icons/*.svg "$dest/icons/"
install -m755 "$here/apply.sh" "$dest/apply.sh"
install -Dm644 "$here/ngosen-breeze-icons.hook" "$ROOT/etc/pacman.d/hooks/ngosen-breeze-icons.hook"
# Older versions used NoUpgrade in pacman.conf; the hook replaces it
sed -i '/^# ngosen-breeze-icons$/,+1d' "$ROOT/etc/pacman.conf"
ROOT=$ROOT "$dest/apply.sh"

# Ngó Sen: use the monochrome icons (not the lotus ones), white for a dark panel
conf=$ROOT$(getent passwd "$owner" | cut -d: -f6)/.config/fcitx5/conf/ngosen.conf
as_owner() { if [[ -n $ROOT ]]; then "$@"; else runuser -u "$owner" -- "$@"; fi; }
if [[ -f $conf ]]; then
  for kv in UseLotusIcons=False IconTheme=Dark; do
    k=${kv%%=*}
    if grep -q "^$k=" "$conf"; then as_owner sed -i "s/^$k=.*/$kv/" "$conf"
    elif grep -q "^# $k=" "$conf"; then as_owner sed -i "s/^# $k=.*/$kv/" "$conf"
    else as_owner sh -c "echo '$kv' >> '$conf'"; fi
  done
else
  as_owner install -Dm600 /dev/stdin "$conf" <<<$'UseLotusIcons=False\nIconTheme=Dark'
fi

echo "Done. Restart fcitx5 and plasmashell (without sudo):"
echo "  $here/restart-fcitx5.sh; systemctl --user restart plasma-plasmashell"
