#!/usr/bin/env zsh

command -v zoxide > /dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v starship > /dev/null 2>&1 && eval "$(starship init zsh)"
command -v opam > /dev/null 2>&1 && eval $(opam env)
