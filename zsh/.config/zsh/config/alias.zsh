#!/usr/bin/env zsh

# Modern alternatives to traditional commands
alias cat='bat'
alias ls='lsd -A'
alias la='lsd -lA'
alias tree='lsd --tree'
alias nano='micro'
alias fetch='fastfetch'
alias claudex='CLAUDE_CODE_SUBAGENT_MODEL=gpt-5.6-sol \
CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1 \
CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=3 \
ENABLE_TOOL_SEARCH=false \
claude --model gpt-5.6-sol'

# Global alias
alias \-g -- --help="--help | bat -plhelp"

docker() {
    if command -v podman >/dev/null 2>&1; then
        podman "$@"
    else
        command docker "$@"
    fi
}
