#!/usr/bin/env zsh

(($+commands[bat])) && alias cat="bat"
(($+commands[lsd])) && alias ls="lsd"
