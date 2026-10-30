#!/usr/bin/env zsh

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME/.git" ]]; then
    mkdir -p "$(dirname "$ZINIT_HOME")" || return 1
    git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" || return 1
fi

if [[ ! -r "$ZINIT_HOME/zinit.zsh" ]]; then
    print -u2 "zinit: bootstrap is incomplete at $ZINIT_HOME"
    return 1
fi

# not to use aliases: zi or zini
typeset -A ZINIT
ZINIT[NO_ALIASES]=1
ZINIT[LIST_COMMAND]='lsd --tree'

source "${ZINIT_HOME}/zinit.zsh"
