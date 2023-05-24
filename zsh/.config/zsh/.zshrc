#!/usr/bin/env zsh

# workaround for vscode terminal
[[ -z "${XDG_CONFIG_HOME}" ]] && export XDG_CONFIG_HOME="${HOME}/.config"
[[ -z "${ZDOTDIR}" ]] && export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"

# some useful options (man zshoptions)
setopt autocd extendedglob nomatch menucomplete
setopt interactive_comments
stty stop undef		# Disable ctrl-s to freeze terminal.
zle_highlight=('paste:none')

# history
setopt appendhistory
setopt incappendhistory     # Immediately append commands to history file.
setopt histignoredups       # Never add duplicate entries.
setopt histignorespace      # Ignore commands that start with a space.
setopt histreduceblanks     # Remove unnecessary blank lines.

# beeping is annoying
unsetopt beep

# remove % symbol on prompt
unsetopt promptsp

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
zsh_add_file "zsh-prompt"

# Plugins
repos=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-completions
  zdharma-continuum/fast-syntax-highlighting
  hlissner/zsh-autopair
)
plugin-load $repos

# Clean startup prompt
! [ -f ~/.hushlogin ] && touch ~/.hushlogin

compinit

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
# bindkey '^e' edit-command-line
