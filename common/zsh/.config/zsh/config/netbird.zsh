#!/usr/bin/env zsh

# NetBird is installed from the official signed .pkg, not Homebrew: the brew
# cask removed the launchd plist in uninstall_preflight and then ran the app's
# installer.sh against the missing service, leaving the daemon crash-looping.
# The pkg's preinstall aborts if the brew formula is present, so keep it out.
nbup() {
    local pkg tmp
    tmp="$(mktemp -d)" || return 1
    pkg="$tmp/netbird.pkg"

    print "netbird: downloading arm64 pkg"
    curl -fL --progress-bar -o "$pkg" "https://pkgs.netbird.io/macos/arm64" || { rm -rf "${tmp:?}"; return 1; }

    if ! pkgutil --check-signature "$pkg" | grep -q "NetBird GmbH"; then
        print -u2 "netbird: unexpected pkg signature, refusing to install"
        rm -rf "${tmp:?}"
        return 1
    fi

    sudo installer -pkg "$pkg" -target / || { rm -rf "${tmp:?}"; return 1; }
    rm -rf "${tmp:?}"

    local i
    for i in {1..30}; do
        [[ -S /var/run/netbird.sock ]] && break
        sleep 1
    done
    /usr/local/bin/netbird status 2>/dev/null |
        grep -E '^(Daemon version|CLI version|Management|Signal|NetBird IP):'
}
