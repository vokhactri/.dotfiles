# Tray icons that match Breeze

```sh
stow tray-icons
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
