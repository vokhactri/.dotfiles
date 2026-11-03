#!/usr/bin/env bash
# Regenerate the app themes from the color scheme and apply Darwin Breeze.
#
# Run `stow -d kde -t "$HOME" theme` from the repo root first.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
data="${XDG_DATA_HOME:-$HOME/.local/share}"

if [ ! -e "$data/color-schemes/DarwinBreezeDark.colors" ]; then
    echo 'DarwinBreezeDark.colors is not installed; run: stow -d kde -t "$HOME" theme' >&2
    exit 1
fi

python3 -I "$here/build.py"

plasma-apply-lookandfeel --apply dev.trivk.darwinbreeze.dark

# plasma-apply-colorscheme skips a scheme that is already active, so edits
# to the .colors file would not be picked up. Bounce through stock Breeze.
plasma-apply-colorscheme BreezeClassic >/dev/null
plasma-apply-colorscheme DarwinBreezeDark >/dev/null

# kde-gtk-config writes gtk.css; add our imports to it.
gtk_import() {
    local css="${XDG_CONFIG_HOME:-$HOME/.config}/$1/gtk.css"
    if [ -e "$css" ] && ! grep -qF "'$2'" "$css"; then
        sed -i "\$a @import '$2';" "$css"
    fi
}
# kde-gtk-config gives GTK apps the KWin title buttons through a GTK module,
# which Helium doesn't load, so it would fall back to Breeze GTK's own
# buttons. Importing the same CSS from gtk.css reaches Helium too.
gtk_import gtk-3.0 window_decorations.css
gtk_import gtk-4.0 window_decorations.css
# Helium's tab strip colors (see chromium.css).
gtk_import gtk-3.0 chromium.css

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

# VS Code only loads themes from installed extensions. --force reinstalls the
# same version, so color changes land without a version bump.
if command -v code >/dev/null; then
    code --install-extension "$here/vscode/darwin-breeze.vsix" --force >/dev/null 2>&1
fi

echo "Applied Darwin Breeze"
if pgrep -x helium >/dev/null; then
    echo "Restart Helium to pick up the new colors"
fi
