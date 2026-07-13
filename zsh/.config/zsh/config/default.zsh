#!/usr/bin/env zsh

export MANWIDTH=999

export EDITOR="micro"
export PAGER="bat"
export VISUAL="micro"
export SUDO_EDITOR="micro"

export STARSHIP_CONFIG="$XDG_CONFIG_HOME"/starship/starship.toml
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true

export PNPM_HOME="$HOME/.local/share/pnpm"

typeset -U path
path=(
  "$HOME/.opencode/bin"
  "$PNPM_HOME/bin"
  $path
)
