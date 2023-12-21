ZAP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zap"
ZAP_SCRIPT="$ZAP_DIR/zap.zsh"
ZAP_BRANCH=release-v1

if [ ! -f $ZAP_SCRIPT ]; then
  git clone -b "$ZAP_BRANCH" https://github.com/zap-zsh/zap.git "$ZAP_DIR" &> /dev/null || { echo "❌ Failed to install Zap" && return 2 }
fi

source "$ZAP_SCRIPT"

repos=(
  # local plugins
  "$ZDOTDIR/aliases.zsh"
  "$ZDOTDIR/exports.zsh"
  "$ZDOTDIR/eval.zsh"
  # remote plugins
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-completions
  zdharma-continuum/fast-syntax-highlighting
  hlissner/zsh-autopair
  wintermi/zsh-brew
  wintermi/zsh-lsd
  zap-zsh/supercharge
  zap-zsh/fzf
  /wintermi/zsh-fnm
)
mac_only_repos=(wintermi/zsh-brew)

case "$(uname -s)" in

Darwin)
	# echo 'Mac OS X'
	;;

Linux)
  for repo in $mac_only_repos; do repos=("${repos[@]/$repo}"); done
	;;

CYGWIN* | MINGW32* | MSYS* | MINGW*)
	# echo 'MS Windows'
	;;
*)
	# echo 'Other OS'
	;;
esac

for repo in $repos; do plug $repo; done

# Clean startup prompt
[ ! -f ~/.hushlogin ] && touch ~/.hushlogin

unsetopt PROMPT_SP

# Load and initialise completion system
autoload -Uz compinit
compinit
