# My personal opinionated dotfiles for `zsh`

## Requirement

- **GNU** `stow`
- `zsh` (I mean, duh)

## Optional

- `unzip` (for `fnm`)

## Installation

1. clone this repo to your `$HOME` and switch to cloned dir:

```
git -C $HOME clone https://github.com/vokhactri/.dotfiles.git && cd "$(basename "$_" .git)"
```

2. use `stow` to symlink configs to `$HOME/.config`:

- to symlink all config dirs
  ```
  stow */
  ```
- to symlink only one config dir, for example `zsh`
  ```
  stow zsh
  ```

3. reload your `zsh` to apply changes:

```
exec zsh
```

## Credit

- [Machfiles](https://github.com/ChristianChiarulli/Machfiles/)
- [zsh_unplugged](https://github.com/mattmc3/zsh_unplugged)
