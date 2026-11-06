#!/usr/bin/env python3
"""Shrink and recolor the tray icons embedded in the netbird-ui binary.

NetBird sends its tray icon as a pixmap, so an icon theme can't replace it.
This rewrites the 48x48 monochrome PNGs inside the binary in place: the
glyph is scaled to SCALE so it gets the padding of a Breeze status icon,
and the white variants take the panel's text color. Each new PNG must fit
in the bytes of the old one; the rest is zero-filled, which Go's PNG
decoder never reads because it stops at IEND.

Usage: patch.py BINARY [--check]
"""

import argparse
import os
from pathlib import Path
import struct
import sys
import tempfile
import zlib

SIZE = 48
SCALE = 0.8
# DarwinBreezeDark ForegroundNormal, as the other tray icons are drawn
LIGHT = (222, 222, 222)
# A glyph narrower than this already has padding (already patched)
MAX_PADDED_WIDTH = round(SIZE * 0.9)
SIG = b"\x89PNG\r\n\x1a\n"

Pixels = list[list[float]]  # rows of premultiplied RGBA floats


def decode(png: bytes) -> tuple[int, int, bytes] | None:
    """Return (width, height, RGBA rows) for an 8-bit RGBA PNG, else None."""
    pos, idat, ihdr = 8, b"", b""
    while pos < len(png):
        (length,) = struct.unpack(">I", png[pos:pos + 4])
        kind, body = png[pos + 4:pos + 8], png[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            ihdr = body
        elif kind == b"IDAT":
            idat += body
        elif kind == b"IEND":
            break
        pos += 12 + length
    w, h, depth, color, _, _, interlace = struct.unpack(">IIBBBBB", ihdr)
    if (depth, color, interlace) != (8, 6, 0):
        return None
    raw, stride, out = zlib.decompress(idat), w * 4, bytearray()
    prev = bytearray(stride)
    for y in range(h):
        ftype = raw[y * (stride + 1)]
        line = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for i in range(stride):
            a = line[i - 4] if i >= 4 else 0
            b = prev[i]
            c = prev[i - 4] if i >= 4 else 0
            if ftype == 1:
                line[i] = (line[i] + a) & 0xFF
            elif ftype == 2:
                line[i] = (line[i] + b) & 0xFF
            elif ftype == 3:
                line[i] = (line[i] + (a + b) // 2) & 0xFF
            elif ftype == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if pa <= pb and pa <= pc else b if pb <= pc else c
                line[i] = (line[i] + pred) & 0xFF
        out += line
        prev = line
    return w, h, bytes(out)


def encode(w: int, h: int, rgba: bytes) -> bytes:
    def chunk(kind: bytes, body: bytes) -> bytes:
        crc = zlib.crc32(kind + body)
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", crc)

    raw = b"".join(b"\0" + rgba[y * w * 4:(y + 1) * w * 4] for y in range(h))
    return (SIG + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def glyph_width(rgba: bytes) -> int:
    xs = [i // 4 % SIZE for i in range(3, len(rgba), 4) if rgba[i] > 16]
    return max(xs) - min(xs) + 1 if xs else 0


def is_light(rgba: bytes) -> bool | None:
    """True for a white glyph, False for black, None if not monochrome."""
    lum = [rgba[i - 3] for i in range(3, len(rgba), 4) if rgba[i] > 200]
    if not lum or any(abs(rgba[i - 3] - rgba[i - 2]) > 8 for i in range(3, len(rgba), 4)
                      if rgba[i] > 200):
        return None
    if all(v > 230 for v in lum):
        return True
    if all(v < 25 for v in lum):
        return False
    return None


def shrink(rgba: bytes, light: bool) -> bytes:
    """Box-filter the image to SCALE, centered on a SIZE canvas."""
    src: Pixels = []
    for y in range(SIZE):
        row: list[float] = []
        for x in range(SIZE):
            r, g, b, a = rgba[(y * SIZE + x) * 4:(y * SIZE + x) * 4 + 4]
            row += [r * a, g * a, b * a, a]
        src.append(row)
    inner = SIZE * SCALE
    off = (SIZE - inner) / 2
    step = 1 / SCALE
    out = bytearray(SIZE * SIZE * 4)

    def spans(o: int) -> list[tuple[int, float]]:
        lo = (o - off) * step
        hi = lo + step
        res = []
        for s in range(max(0, int(lo)), min(SIZE, int(hi) + 1)):
            cover = min(hi, s + 1) - max(lo, s)
            if cover > 0:
                res.append((s, cover))
        return res

    for oy in range(SIZE):
        ys = spans(oy)
        for ox in range(SIZE):
            acc = [0.0] * 4
            for sy, wy in ys:
                for sx, wx in spans(ox):
                    k = wy * wx
                    for c in range(4):
                        acc[c] += src[sy][sx * 4 + c] * k
            area = step * step
            a = acc[3] / area
            if a < 0.5:
                continue
            color = LIGHT if light else tuple(round(acc[c] / acc[3]) for c in range(3))
            out[(oy * SIZE + ox) * 4:(oy * SIZE + ox) * 4 + 4] = bytes(
                [*color, min(255, round(a))])
    return bytes(out)


def patch(data: bytearray) -> int:
    count, pos = 0, 0
    while (pos := data.find(SIG, pos)) >= 0:
        end = data.find(b"IEND", pos) + 8
        old = bytes(data[pos:end])
        img = decode(old) if old[16:24] == struct.pack(">II", SIZE, SIZE) else None
        if img is not None:
            light = is_light(img[2])
            if light is not None and glyph_width(img[2]) > MAX_PADDED_WIDTH:
                new = encode(SIZE, SIZE, shrink(img[2], light))
                if len(new) > len(old):
                    sys.exit(f"Patched icon at {pos} is larger than the original")
                data[pos:end] = new + bytes(len(old) - len(new))
                count += 1
        pos = end
    return count


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("binary", type=Path)
    parser.add_argument("--check", action="store_true",
                        help="only print how many icons would be patched")
    args = parser.parse_args()
    data = bytearray(args.binary.read_bytes())
    count = patch(data)
    print(f"{args.binary}: {count} tray icons {'to patch' if args.check else 'patched'}")
    if args.check or not count:
        return
    mode = args.binary.stat().st_mode
    fd, tmp = tempfile.mkstemp(dir=args.binary.parent, prefix=".netbird-ui.")
    with os.fdopen(fd, "wb") as f:
        f.write(data)
    os.chmod(tmp, mode & 0o7777)
    os.replace(tmp, args.binary)


if __name__ == "__main__":
    main()
