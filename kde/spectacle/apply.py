#!/usr/bin/env python3
"""Apply screenshot preferences and reload Spectacle's KDE shortcuts."""

import ast
import configparser
import os
from pathlib import Path
import re
import subprocess


HERE = Path(__file__).resolve().parent
COMPONENT = "org.kde.spectacle.desktop"
ACCEL = "/component/org_kde_spectacle_desktop"


def run(*args, **kwargs):
    return subprocess.run(args, check=True, text=True, **kwargs)


def accel(path, method, *args):
    return run(
        "gdbus", "call", "--session", "--dest", "org.kde.kglobalaccel",
        "--object-path", path, "--method", method, *args,
        capture_output=True,
    ).stdout


def main():
    for name in ("spectaclerc", "klipperrc"):
        config = configparser.ConfigParser(interpolation=None)
        config.optionxform = str
        config.read(HERE / "settings" / name)
        for group in config.sections():
            for key, value in config[group].items():
                run("kwriteconfig6", "--file", name, "--group", group,
                    "--key", key, value)

    # T3's locale and XDG_DATA_DIRS can differ from the running KDE session.
    # Build the cache KDE actually reads, rather than an app-specific cache.
    session = dict(
        line.split("=", 1) for line in
        run("systemctl", "--user", "show-environment", capture_output=True)
        .stdout.splitlines() if "=" in line
    )
    env = os.environ.copy()
    for key in ("LANG", "LANGUAGE", "XDG_DATA_DIRS", "XDG_DATA_HOME",
                "XDG_CACHE_HOME", "XDG_CONFIG_HOME"):
        env.pop(key, None)
        if key in session:
            env[key] = session[key]
    for key in set(env) | set(session):
        if key.startswith("LC_"):
            env.pop(key, None)
            if key in session:
                env[key] = session[key]
    run("kbuildsycoca6", "--noincremental", env=env)

    # Existing shortcut components retain their old Exec commands. Recreate
    # only Spectacle's component, preserving any customized key bindings.
    try:
        output = accel(ACCEL, "org.kde.kglobalaccel.Component.allShortcutInfos")
    except subprocess.CalledProcessError:
        shortcuts = []  # Component has not been registered yet.
    else:
        shortcuts = ast.literal_eval(re.sub(r"@a[is] ", "", output))[0]
        accel(ACCEL, "org.kde.kglobalaccel.Component.cleanUp")

    action = [COMPONENT, "_reload_config", "Spectacle", "Reload configuration"]
    accel("/kglobalaccel", "org.kde.KGlobalAccel.doRegister", repr(action))
    accel("/kglobalaccel", "org.kde.KGlobalAccel.unregister",
          COMPONENT, "_reload_config")
    for name, label, component, friendly, context, _, keys, defaults in shortcuts:
        if keys != defaults:
            identity = component if context == "default" else f"{component}|{context}"
            accel("/kglobalaccel", "org.kde.KGlobalAccel.setForeignShortcut",
                  repr([identity, name, friendly, label]), repr(keys))

    run("qdbus6", "org.kde.klipper", "/klipper",
        "org.kde.klipper.klipper.reloadConfig")
    print("Applied Spectacle: copy to clipboard with a notification, no preview.")


if __name__ == "__main__":
    main()
