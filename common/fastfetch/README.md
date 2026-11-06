# Fastfetch

```sh
stow -d common -t "$HOME" fastfetch
```

The logo is `albedo.png`, sent inline through the kitty graphics protocol from
the pre-encoded `albedo.kitty`. This works in Ghostty and Kwi. The
`kitty-direct` logo type is not used because Kwi ignores images passed as a
file path.

After changing `albedo.png` or the logo size in `config.jsonc`, regenerate the
logo from the repository root:

```sh
python3 common/fastfetch/build.py
```
