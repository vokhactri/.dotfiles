#!/usr/bin/env zsh

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

# not to use aliases: zi or zini
declare -A ZINIT
ZINIT[NO_ALIASES]=1
ZINIT[LIST_COMMAND]='lsd --tree'

source "${ZINIT_HOME}/zinit.zsh"
