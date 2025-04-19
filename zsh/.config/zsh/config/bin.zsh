#!/usr/bin/env zsh

# Define a marker file (choose a location in your cache or temp directory)
MARKER_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/gnu_tools_symlinked"

if [[ ! -f "$MARKER_FILE" ]]; then
    gnu_tools=(
        "coreutils"
        "findutils"
        "gnu-tar"
        "gnu-sed"
        "gawk"
        "gnu-indent"
        "grep"
    )

    for tool in $gnu_tools; do
        gnubin="/opt/homebrew/opt/$tool/libexec/gnubin"
        if [ -d "$gnubin" ]; then
            for bin in "$gnubin"/*; do
                ln -sf "$bin" "$XDG_BIN_HOME/$(basename "$bin")"
            done
        fi
    done

    # Create the marker file to indicate the script has run
    touch "$MARKER_FILE"
fi


local bin_paths=(
    "$XDG_BIN_HOME"
    "/opt/homebrew/opt/gnu-getopt/bin"
)
for bin_path in "${bin_paths[@]}"; do
    if [ -d "$bin_path" ]; then
        case ":$PATH:" in
            *":$bin_path:"*) ;;
            *) PATH="$bin_path:$PATH" ;;
        esac
    fi
done
