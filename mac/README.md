# macOS packages

From the repository root, install all macOS packages:

```sh
(cd mac && stow -t "$HOME" */)
```

Install the package:

```sh
stow -d mac -t "$HOME" ghostty
```

- `ghostty`: JetBrainsMono Nerd Font and Ghostty's bundled SpaceGray Eighties theme.
