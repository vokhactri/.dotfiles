# My personal dotfiles

## Requirement

- **GNU** `stow`

## Installation

1. clone repo to your `$HOME` dir

```
  git -C $HOME clone https://github.com/vokhactri/.dotfiles.git
```

2. go to repo directory that you've cloned

```
cd .dotfiles
```

3. use `stow` to symlink all configs to `$HOME/.config` dir:

- to symlink for config dirs
  ```
  stow */
  ```
- to symlink only one config dir, for example `zsh`
  ```
  stow zsh
  ```

## Credit

- [Machfiles](https://github.com/ChristianChiarulli/Machfiles/)
- [zsh_unplugged](https://github.com/mattmc3/zsh_unplugged)
