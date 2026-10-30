# Spectacle

Capture screenshots in the background, copy the image to the clipboard, and
show a completion notification. Screenshots are not automatically saved.

```sh
stow -d kde -t "$HOME" spectacle
./kde/spectacle/apply.py
```

Requires Spectacle, KDE Plasma 6, GNU Stow, Python 3, `kwriteconfig6`,
`kbuildsycoca6`, `qdbus6`, and `gdbus`. Run the apply script in your KDE session.
Move any existing files reported as conflicts by Stow out of the way first.

- **Print** / **Meta+Shift+S**: select a rectangular region.
- **Shift+Print**: entire desktop.
- **Meta+Print**: active window.
- **Meta+Shift+Print**: select a rectangular region.
- **Meta+Ctrl+Print**: window under the cursor.

The desktop launcher and shortcut entry are managed by Stow. The files in
`settings/` are merged into `~/.config/spectaclerc` and `~/.config/klipperrc`
by `apply.py`, preserving unrelated preferences and window state. Klipper's
`SaveImages=true` keeps captured images available after Spectacle exits.

After editing settings or launcher commands, run `apply.py` again. It rebuilds
the cache using the KDE session's environment and reloads only Spectacle's
shortcut component, preserving custom key bindings.
