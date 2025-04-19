#!/usr/bin/env zsh

# Modern alternatives to traditional commands
alias cat='bat'
alias ls='lsd -A'
alias la='lsd -lA'
alias tree='lsd --tree'
alias nano='micro'
alias fetch='fastfetch'

# Git shortcuts
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

docker() {
    if command -v podman >/dev/null 2>&1; then
        podman "$@"
    else
        command docker "$@"
    fi
}
