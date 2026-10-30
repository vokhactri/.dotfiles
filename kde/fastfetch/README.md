# Fastfetch for Konsole

From the repository root:

```sh
stow -d kde -t "$HOME" fastfetch
```

The configuration, source PNG, and generated logo live in
`kde/fastfetch/.config/fastfetch/`. The generated logo is included, so a new
machine does not need to run the build script.

Choose either this package or `mac/fastfetch`; both own `~/.config/fastfetch/`.

Konsole needs inline image data instead of the original `kitty-direct` file
transfer. The committed `albedo-konsole.kitty` logo is pre-scaled to 20 × 10
cells to avoid grainy terminal scaling.

After changing `albedo.png`, the logo dimensions, or Konsole's font, update
the cell size in `build.py` and regenerate the logo from the repository root:

```sh
python3 kde/fastfetch/build.py
```

The build script requires `vipsthumbnail` from libvips.
