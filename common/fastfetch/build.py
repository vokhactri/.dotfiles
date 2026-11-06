#!/usr/bin/env python3
"""Encode albedo.png as kitty graphics escapes for fastfetch's "raw" logo.

fastfetch's "kitty-direct" logo sends the terminal a file path (t=f), which
Kwi ignores. This file carries the PNG inline (t=d) instead, so it works in
any terminal with the kitty graphics protocol, Ghostty and Kwi included. q=2
keeps the terminal from answering. Rerun after changing the image or the
logo size.
"""

import base64
from pathlib import Path

DIR = Path(__file__).resolve().parent / ".config/fastfetch"
# Logo size in cells; keep in sync with "width" and "height" in config.jsonc.
COLS, ROWS = 20, 10


def encode(png: bytes) -> bytes:
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
    return bytes(out)


(DIR / "albedo.kitty").write_bytes(encode((DIR / "albedo.png").read_bytes()))
