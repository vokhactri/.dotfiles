#!/bin/bash
# Restart fcitx5 through KWin (KDE Wayland) so it keeps the Wayland input method frontend.
L=$(kreadconfig6 --file kwinrc --group Wayland --key InputMethod)
[[ -n $L ]] || L=/usr/share/applications/fcitx5-wayland-launcher.desktop
pkill -x fcitx5; sleep 1
kwriteconfig6 --notify --file kwinrc --group Wayland --key InputMethod --delete; sleep 1
kwriteconfig6 --notify --file kwinrc --group Wayland --key InputMethod "$L"
