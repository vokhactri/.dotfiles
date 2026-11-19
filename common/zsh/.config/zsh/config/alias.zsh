#!/usr/bin/env zsh

# Modern alternatives to traditional commands
alias cat='bat'
alias ls='lsd -A'
alias la='lsd -lA'
alias tree='lsd --tree'
alias nano='micro'
alias fetch='fastfetch'

# Global alias
alias \-g -- --help="--help | bat -plhelp"
