# My personal opinionated dotfiles for `zsh`

## Requirement

- **GNU** `stow`
- `zsh` (I mean, duh)

## Optional

- `unzip` (for `fnm`)

## Installation

1. clone this repo to your `$HOME` and switch to cloned dir:

```sh
git -C $HOME clone https://github.com/vokhactri/.dotfiles.git && cd $HOME/.dotfiles
```

2. use `stow` to symlink configs to `$HOME/.config`:

- to symlink all config dirs
  ```sh
  stow */
  ```
- to symlink only one config dir, for example `zsh`
  ```sh
  stow zsh
  ```

3. reload your `zsh` to apply changes:

```sh
exec zsh
```

## Credit

- [Machfiles](https://github.com/ChristianChiarulli/Machfiles/)
- [zsh_unplugged](https://github.com/mattmc3/zsh_unplugged)
- [ayanrajpoot10/dotfiles](https://github.com/ayanrajpoot10/dotfiles)
