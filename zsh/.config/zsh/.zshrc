ZAP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zap"
ZAP_SCRIPT="$ZAP_DIR/zap.zsh"
ZAP_BRANCH=release-v1

if [ ! -f $ZAP_SCRIPT ]; then
  git clone -b "$ZAP_BRANCH" https://github.com/zap-zsh/zap.git "$ZAP_DIR"
fi

source "$ZAP_SCRIPT"

remote_plugins=(
  zap-zsh/supercharge
  zap-zsh/fzf
  wintermi/zsh-lsd
  wintermi/zsh-fnm
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-completions
  zdharma-continuum/fast-syntax-highlighting
  hlissner/zsh-autopair
)
plugins=("${remote_plugins[@]}" "$ZDOTDIR/*")
mac_plugins=(wintermi/zsh-brew)

case "$(uname -s)" in
Darwin)
	# echo 'Mac OS X'
  plugins=("${mac_plugins[@]}" "${plugins[@]}")
	;;
Linux)
  # echo 'Linux'
	;;
CYGWIN* | MINGW32* | MSYS* | MINGW*)
	# echo 'MS Windows'
	;;
*)
	# echo 'Other OS'
	;;
esac

for plugin in $plugins; do plug $plugin; done

# Clean startup prompt
[ ! -f ~/.hushlogin ] && touch ~/.hushlogin

unsetopt PROMPT_SP

# Load and initialise completion system
autoload -Uz compinit
compinit
