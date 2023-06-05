# Created by Zap installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

repos=(
  # remote plugins
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-completions
  wintermi/zsh-brew
  wintermi/zsh-lsd
  zap-zsh/supercharge
  zap-zsh/fzf
  zap-zsh/fnm
  zdharma-continuum/fast-syntax-highlighting
  hlissner/zsh-autopair
  # local plugins
  "$ZDOTDIR/aliases.zsh"
  "$ZDOTDIR/exports.zsh"
  "$ZDOTDIR/eval.zsh"
)

for repo in $repos; do plug $repo; done

# Clean startup prompt
! [ -f ~/.hushlogin ] && touch ~/.hushlogin

# Load and initialise completion system
autoload -Uz compinit
compinit
