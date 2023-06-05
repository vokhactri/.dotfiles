ZAP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zap"
ZAP_SCRIPT="$ZAP_DIR/zap.zsh"
ZAP_BRANCH=release-v1

if [ ! -f $ZAP_SCRIPT ]; then
  git clone -b "$ZAP_BRANCH" https://github.com/zap-zsh/zap.git "$ZAP_DIR" &> /dev/null || { echo "❌ Failed to install Zap" && return 2 }
else
  source "$ZAP_SCRIPT"
fi

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
[ ! -f ~/.hushlogin ] && touch ~/.hushlogin

# Load and initialise completion system
autoload -Uz compinit
compinit
