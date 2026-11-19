export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Bash-like globs and word splitting for Claude Code's `zsh -c` commands.
if [[ -n "$CLAUDECODE" && -n "$ZSH_EXECUTION_STRING" ]]; then
    setopt SH_WORD_SPLIT NO_NOMATCH
fi

# Per-machine settings that stay out of the repo, like PATH entries for a VPS.
[ -r "$XDG_CONFIG_HOME/zshenv.local" ] && . "$XDG_CONFIG_HOME/zshenv.local"
