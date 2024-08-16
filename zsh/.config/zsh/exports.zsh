#!/usr/bin/env zsh

HISTSIZE=1000000
SAVEHIST=1000000

export MANWIDTH=999

export EDITOR="micro"
export PAGER="bat"
export VISUAL="micro"
export SUDO_EDITOR="micro"

export STARSHIP_CONFIG="$XDG_CONFIG_HOME"/starship/starship.toml
