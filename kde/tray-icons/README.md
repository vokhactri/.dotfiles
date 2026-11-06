# Tray icons that match Breeze

```sh
stow -d kde -t "$HOME" tray-icons
```

Some icons need one more step after stowing; see below.

## Ngó Sen (fcitx5-ngosen)

Replaces Ngó Sen's monochrome tray icons with a V/E inside a rounded frame.

```sh
sudo ~/.local/share/ngosen-breeze-icons/install.sh
~/.local/share/ngosen-breeze-icons/restart-fcitx5.sh
systemctl --user restart plasma-plasmashell
```

- Ngó Sen points the tray at `/usr/share/icons/hicolor`, but Plasma looks
  the icon up by name in the `breeze`/`breeze-dark` themes under
  `/usr/share` and ignores `~/.local/share/icons`, so the system files have
  to be replaced.
- `install.sh` copies the icons and `apply.sh` to
  `/usr/local/share/ngosen-breeze-icons/`, installs the pacman hook
  `/etc/pacman.d/hooks/ngosen-breeze-icons.hook` to re-apply them after
  every package upgrade, and sets `UseLotusIcons=False` and
  `IconTheme=Dark` in `~/.config/fcitx5/conf/ngosen.conf`.
- The original icons are kept in `/usr/local/share/ngosen-breeze-icons/orig/`;
  `sudo ~/.local/share/ngosen-breeze-icons/restore.sh` puts them back and
  removes the hook.
- On KDE Wayland don't start fcitx5 with `fcitx5 -d`; use
  `restart-fcitx5.sh` so KWin launches it.

## NetBird (netbird-ui)

Scales NetBird's tray icons down to 80% so they get the padding of Breeze
status icons, and draws the white ones in the panel's text color
(`#dedede`) instead of pure white.

```sh
sudo ~/.local/share/netbird-breeze-icons/install.sh
pkill -x netbird-ui; setsid -f netbird-ui --daemon-addr unix:///var/run/netbird/main.sock >/dev/null 2>&1
```

- NetBird sends the tray icon as raw pixels, not an icon name, so an icon
  theme can't replace it. `patch.py` rewrites the 48x48 PNGs embedded in
  `/usr/bin/netbird-ui` in place instead; each new PNG fits in the bytes
  of the old one.
- `install.sh` copies `patch.py` and `apply.sh` to
  `/usr/local/share/netbird-breeze-icons/` and installs the pacman hook
  `/etc/pacman.d/hooks/netbird-breeze-icons.hook` to re-patch the binary
  after every `netbird-ui`/`netbird-ui-bin` upgrade.
- The original binary is kept in `/usr/local/share/netbird-breeze-icons/orig/`;
  `sudo ~/.local/share/netbird-breeze-icons/restore.sh` puts it back and
  removes the hook.

## qBittorrent

`qbittorrent-tray-mono.svg` is qBittorrent's monochrome tray icon scaled
down to 78%, so it has the same padding as Breeze status icons instead of
filling the whole tray slot.

qBittorrent 5.x only looks the tray icon up in the icon theme when "Use
icons from system theme" is on, so also set (qBittorrent closed, or via
Tools > Options > Behavior):

```ini
# ~/.config/qBittorrent/qBittorrent.conf
[Appearance]
TrayIconStyle=Monochrome

[Preferences]
Advanced\useSystemIconTheme=true
```

`qBittorrent.conf` itself isn't stowed: qBittorrent rewrites it on exit.
