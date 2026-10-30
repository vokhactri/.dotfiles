# Personal dotfiles

These are my config files for macOS and KDE, managed with GNU Stow. You need `stow` and `zsh` installed.

## Installation

```sh
git clone https://github.com/vokhactri/.dotfiles.git "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
```

The packages are split into three groups:

- [common/](common/README.md) has Git, Micro, mpv, npm, Starship and Zsh.
- [mac/](mac/README.md) has Ghostty and the original Fastfetch config.
- [kde/](kde/README.md) has the Darwin Breeze theme, Helium, Konsole Fastfetch, Spectacle and tray icons.

Install all of `common`, then the group for your platform:

```sh
(cd common && stow -t "$HOME" */)
(cd mac && stow -t "$HOME" */)   # macOS
(cd kde && stow -t "$HOME" */)   # KDE
```

`*/` matches every package in the group. Each line runs in a subshell, so you stay in the repo root and can run them one after another. KDE needs a few more steps after this. They're in [`kde/README.md`](kde/README.md).

### Picking packages

You don't have to install everything. List only the packages you want:

```sh
stow -d common -t "$HOME" git zsh starship
stow -d mac -t "$HOME" ghostty
stow -d kde -t "$HOME" spectacle fastfetch
```

`-d` tells Stow which group to read from. `-t` puts the symlinks in your home directory. You can mix packages from different groups. Fastfetch is the exception. Install `mac/fastfetch` or `kde/fastfetch`, never both.

### Previewing and removing

`-n -v` prints what Stow would do and changes nothing. `-D` removes the symlinks. Pass the same `-d` and `-t` you used to install:

```sh
stow -n -v -d kde -t "$HOME" spectacle
stow -D -d kde -t "$HOME" spectacle
```

Once the Zsh config is linked, run `exec zsh` to reload the shell.

## Credits

- [Machfiles](https://github.com/ChristianChiarulli/Machfiles/)
- [zsh_unplugged](https://github.com/mattmc3/zsh_unplugged)
- [ayanrajpoot10/dotfiles](https://github.com/ayanrajpoot10/dotfiles)
