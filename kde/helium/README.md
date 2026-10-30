# Helium

Browser flags and the generated Darwin Breeze theme. From the repository root:

```sh
stow -d kde -t "$HOME" helium
```

The theme files are included, so the KDE `theme` package does not need to be
stowed to use Helium's theme. To regenerate its colors from the shared color
scheme, run `python3 kde/theme/build.py` and restart Helium.
