# Common packages

Shared configuration for Git, Micro, mpv, npm, Starship, and Zsh.
From the repository root, install all shared packages:

```sh
(cd common && stow -t "$HOME" */)
```

Or choose individual packages:

```sh
stow -d common -t "$HOME" git
stow -d common -t "$HOME" zsh starship
```

Choose any of `git`, `micro`, `mpv`, `npm`, `starship`, and `zsh`.
Reload Zsh with `exec zsh` after installing its configuration.
