#!/usr/bin/env zsh

local brew_prefix="${HOMEBREW_PREFIX:-}"
if [[ -z "$brew_prefix" ]] && command -v brew >/dev/null 2>&1; then
    brew_prefix="$(brew --prefix 2>/dev/null)"
fi

if [[ -n "$brew_prefix" ]]; then
    gnu_tools=(
        "coreutils"
        "findutils"
        "gnu-tar"
        "gnu-sed"
        "gawk"
        "gnu-indent"
        "grep"
    )

    if mkdir -p "$XDG_BIN_HOME"; then
        for tool in $gnu_tools; do
            gnubin="$brew_prefix/opt/$tool/libexec/gnubin"
            if [[ -d "$gnubin" ]]; then
                for bin in "$gnubin"/*(N); do
                    target="$XDG_BIN_HOME/${bin:t}"
                    [[ "$target" -ef "$bin" ]] || ln -sf "$bin" "$target"
                done
            fi
        done
    fi
fi

local bin_paths=(
    "$XDG_BIN_HOME"
    "${brew_prefix:+$brew_prefix/opt/gnu-getopt/bin}"
)
for bin_path in "${bin_paths[@]}"; do
    if [[ -d "$bin_path" ]]; then
        case ":$PATH:" in
            *":$bin_path:"*) ;;
            *) path=("$bin_path" $path) ;;
        esac
    fi
done
