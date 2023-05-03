# Set PATH, MANPATH, etc., for Homebrew.
[ -x `command -v brew` ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -x `command -v fnm` ] && eval "$(fnm env --use-on-cd)"
