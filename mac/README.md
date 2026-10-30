# macOS packages

From the repository root, install all macOS packages:

```sh
(cd mac && stow -t "$HOME" */)
```

Or choose individual packages:

```sh
stow -d mac -t "$HOME" ghostty
stow -d mac -t "$HOME" fastfetch
```

- `ghostty`: JetBrainsMono Nerd Font and Ghostty's bundled SpaceGray Eighties theme.
- `fastfetch`: the original configuration, with a `kitty-direct` image logo.
  Its source PNG is included in `fastfetch/.config/fastfetch/`.

These packages are independent. Choose either `mac/fastfetch` or
`kde/fastfetch`; both own `~/.config/fastfetch/`.
