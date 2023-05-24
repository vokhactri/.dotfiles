# Set PATH, MANPATH, etc., for Homebrew.
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
command -v fnm > /dev/null 2>&1 && eval "$(fnm env --use-on-cd)"
command -v zoxide > /dev/null 2>&1 && eval "$(zoxide init zsh)"
