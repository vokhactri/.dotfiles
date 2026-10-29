#!/usr/bin/env bash
# Regenerate the app themes from the color scheme and apply Darwin Breeze.
#
# Run `stow darwin-breeze helium` first.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
data="${XDG_DATA_HOME:-$HOME/.local/share}"

if [ ! -e "$data/color-schemes/DarwinBreezeDark.colors" ]; then
    echo "DarwinBreezeDark.colors is not installed; run 'stow darwin-breeze' in ~/.dotfiles" >&2
    exit 1
fi

python3 -I "$here/build.py"

plasma-apply-lookandfeel --apply dev.trivk.darwinbreeze.dark

# plasma-apply-colorscheme skips a scheme that is already active, so edits
# to the .colors file would not be picked up. Bounce through stock Breeze.
plasma-apply-colorscheme BreezeClassic >/dev/null
plasma-apply-colorscheme DarwinBreezeDark >/dev/null

# Drop the line under the title bar so it blends into the toolbar.
kwriteconfig6 --file breezerc --group Windeco --key DrawTitleBarSeparator false

# A wallpaper-derived accent color would override the blue from the scheme.
kwriteconfig6 --file kdeglobals --group General --key AccentColor --delete
kwriteconfig6 --file kdeglobals --group General --key accentColorFromWallpaper false

qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null \
    || dbus-send --session --type=signal /KWin org.kde.KWin.reloadConfig

# T3 Code skips symlinked theme files, so publish a copy instead of stowing it.
t3="$(command -v t3 || echo "$HOME/.t3/bin/t3")"
if [ -x "$t3" ]; then
    "$t3" theme set "$here/t3/darwin-breeze.json" >/dev/null
fi

echo "Applied Darwin Breeze"
if pgrep -x helium >/dev/null; then
    echo "Restart Helium to pick up its theme"
fi
