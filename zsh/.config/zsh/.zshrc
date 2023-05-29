#!/usr/bin/env zsh

# some useful options (man zshoptions)
setopt AUTO_CD EXTENDED_GLOB NOMATCH MENU_COMPLETE
setopt INTERACTIVE_COMMENTS
stty stop undef		# Disable ctrl-s to freeze terminal.
zle_highlight=('paste:none')

# history
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

unsetopt EXTENDED_HISTORY

# beeping is annoying
unsetopt BEEP

# remove % symbol on prompt
unsetopt PROMPT_SP

# completions

# for brew
if type brew &>/dev/null
then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

autoload -Uz compinit
zstyle ':completion:*' menu select
# zstyle ':completion::complete:lsof:*' menu yes select
zmodload zsh/complist
# compinit
_comp_options+=(globdots)		# Include hidden files.

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Colors
autoload -Uz colors && colors

# Useful Functions
source "$ZDOTDIR/zsh-functions"

# Normal files to source
zsh_add_file "zsh-exports"
zsh_add_file "zsh-aliases"
zsh_add_file "zsh-eval"

# Plugins
repos=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-completions
  zap-zsh/fzf
  zap-zsh/fnm
  zdharma-continuum/fast-syntax-highlighting
  hlissner/zsh-autopair
  wintermi/zsh-lsd
)
plugin-load $repos

# Clean startup prompt
! [ -f ~/.hushlogin ] && touch ~/.hushlogin

compinit

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
# bindkey '^e' edit-command-line
