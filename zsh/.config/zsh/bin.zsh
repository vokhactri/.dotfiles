#!/usr/bin/env zsh

export LOCAL_BIN="$HOME/.local/bin"
if ! [ -d "$LOCAL_BIN" ]; then
    mkdir -p "$LOCAL_BIN"
fi
case ":$PATH:" in
    *":$LOCAL_BIN:"*) ;;
    *) export PATH="$LOCAL_BIN:$PATH" ;;
esac
