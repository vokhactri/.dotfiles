# KDE Plasma packages

From the repository root, install all KDE packages:

```sh
(cd kde && stow -t "$HOME" */)
```

Or choose individual packages:

```sh
stow -d kde -t "$HOME" spectacle helium
```

| Package                            | Details                                                  |
| ---------------------------------- | -------------------------------------------------------- |
| [theme](theme/README.md)           | Darwin Breeze KDE colors and generated app themes        |
| [helium](helium/README.md)         | Browser flags; colors come from GTK                      |
| [spectacle](spectacle/README.md)   | Screenshots to clipboard with a notification, no preview |
| [tray-icons](tray-icons/README.md) | Ngó Sen and qBittorrent tray icons                       |

Theme and Spectacle need an additional apply step after stowing their package:

```sh
# If you selected theme:
./kde/theme/apply.sh
# If you selected spectacle:
./kde/spectacle/apply.py
```

The apply scripts require a running KDE Plasma 6 session. Ngó Sen icons need
an additional install step described in the tray-icons README.

Packages can be selected independently; Helium follows the Darwin Breeze
colors only when the theme is applied.
