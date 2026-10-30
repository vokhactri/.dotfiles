#!/usr/bin/env python3
"""Encode albedo.png as kitty graphics escapes for fastfetch's "raw" logo.

fastfetch's "kitty-direct" logo sends the terminal a file path (t=f). Konsole
only accepts inline data (t=d) and answers t=f with ENOTSUPPORTED, which lands
on the prompt as typed input. These files carry the PNG inline instead, with
q=2 so the terminal never answers at all.

  .config/fastfetch/albedo-konsole.kitty   pre-scaled for Konsole

Konsole stretches the image to the c x r cell box with nearest-neighbour
scaling, at logical (not device) pixel size, so a 512px source turns grainy.
The Konsole copy is resized with Lanczos to exactly that box, which leaves
Konsole nothing to scale. Rerun after changing the image, the logo size or the
Konsole font.
"""

import base64
import subprocess
import tempfile
from pathlib import Path

PKG = Path(__file__).resolve().parent
DIR = PKG / ".config/fastfetch"
SOURCE = DIR / "albedo.png"
# Logo size in cells; keep in sync with "width" and "height" in config.jsonc.
COLS, ROWS = 20, 10
# Konsole's cell size in logical pixels for JetBrainsMono Nerd Font 10pt
# (QFontMetrics: average advance of Konsole's REPCHAR, and height()).
KONSOLE_CELL = 8, 17


def encode(png, dst):
    data = base64.b64encode(png)
    chunks = [data[i : i + 4096] for i in range(0, len(data), 4096)]
    out = bytearray()
    for n, chunk in enumerate(chunks):
        more = int(n < len(chunks) - 1)
        if n == 0:
            keys = b"a=T,f=100,t=d,c=%d,r=%d,q=2,m=%d" % (COLS, ROWS, more)
        else:
            keys = b"m=%d" % more
        out += b"\x1b_G" + keys + b";" + chunk + b"\x1b\\"
    dst.write_bytes(out)


def resize(width, height):
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "out.png"
        subprocess.run(
            ["vipsthumbnail", SOURCE, "--size", f"{width}x{height}!", "-o", out],
            check=True,
        )
        return out.read_bytes()


encode(resize(COLS * KONSOLE_CELL[0], ROWS * KONSOLE_CELL[1]), DIR / "albedo-konsole.kitty")
