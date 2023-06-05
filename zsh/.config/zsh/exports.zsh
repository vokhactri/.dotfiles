#!/usr/bin/env zsh

HISTFILE="$ZDOTDIR"/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

export MANWIDTH=999

export EDITOR="micro"
export PAGE="bat"
export VISUAL="micro"

export STARSHIP_CONFIG="$XDG_CONFIG_HOME"/starship/starship.toml

export NODE_OPTIONS="--dns-result-order=ipv4first"