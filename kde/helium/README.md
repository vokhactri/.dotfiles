# Helium

Browser flags for hardware video decoding on Wayland and for colors that
match KDE apps. From the repository root:

```sh
stow -d kde -t "$HOME" helium
```

Helium takes its colors and window buttons from GTK. In Settings →
Appearance, set Theme to GTK and turn off "Use system title bar and borders".
With the KDE `theme` package applied, GTK follows the Darwin Breeze colors and
the window buttons match KWin's; see
[Darwin Breeze → Helium notes](../theme/README.md#helium-notes).
