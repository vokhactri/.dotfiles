#!/usr/bin/env python3
"""Generate app themes from the Darwin Breeze KDE color scheme.

.local/share/color-schemes/DarwinBreezeDark.colors is the only place colors
are defined. This script derives from it:

  .local/share/helium-themes/darwinbreeze/manifest.json
  .config/ghostty/themes/DarwinBreezeDark
  t3/darwin-breeze.json   (published to T3 Code by apply.sh)
  telegram/DarwinBreezeDark.tdesktop-theme   (not committed; imported into Telegram by hand)
  vscode/   (packed into vscode/darwin-breeze.vsix, installed by apply.sh)
"""

import colorsys
import configparser
import io
import json
import re
import struct
import zipfile
import zlib
from pathlib import Path

PKG = Path(__file__).resolve().parent
SCHEME = PKG / ".local/share/color-schemes/DarwinBreezeDark.colors"
HELIUM = PKG / ".local/share/helium-themes/darwinbreeze"
GHOSTTY = PKG / ".config/ghostty/themes/DarwinBreezeDark"
T3 = PKG / "t3/darwin-breeze.json"
# Telegram Desktop's built-in night theme, used as the base for every key the
# scheme has no role for: the colors file from telegramdesktop/tdesktop at
# 837b256, Telegram/Resources/night.tdesktop-theme.
TELEGRAM_BASE = PKG / "telegram/night.tdesktop-palette"
TELEGRAM = PKG / "telegram/DarwinBreezeDark.tdesktop-theme"
VSCODE = PKG / "vscode"
VSCODE_THEME = "themes/DarwinBreezeDark-color-theme.json"
# VS Code's default dark theme, Dark 2026 (which includes Dark Modern, Dark+
# and Visual Studio Dark), from Code - OSS 1.138 extensions/theme-defaults.
# The workbench colors start from it.
VSCODE_UI = PKG / "vscode/base/2026-dark.json"
# Pierre Dark, the syntax theme T3 Code highlights code with (from T3 Code
# 0.1.4). The editor uses its token colors as they are.
VSCODE_SYNTAX = PKG / "vscode/base/pierre-dark.json"

WHITE = (255, 255, 255)

# Apple systemCyan; the KDE scheme has no cyan role.
CYAN = (100, 210, 255)

# Apple systemYellow; search highlights in T3 Code.
YELLOW = (255, 255, 0)

# Breeze draws inactive tabs this far from the window color towards the text
# color (measured in Dolphin: 40 -> 62 with text 222).
INACTIVE_TAB_MIX = 0.12


def load():
    cp = configparser.ConfigParser(interpolation=None, strict=False)
    cp.optionxform = str
    cp.read(SCHEME)

    def color(group, key):
        return tuple(int(v) for v in cp[f"Colors:{group}"][key].split(","))

    return color


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def hexc(c):
    """#rrggbb, or #rrggbbaa when c carries an alpha."""
    return "#" + "".join(f"{v:02x}" for v in c)


def kwin_compensate(c):
    """Pre-distort a color for Chromium on KWin.

    Chromium tags its surfaces as sRGB, KWin shows them with a gamma 2.2
    curve, so dark grays come out lighter (40 -> 44). Encoding the target
    with the inverse makes Helium land on the same values as native apps.
    """

    def ch(v):
        lin = (v / 255) ** 2.2
        enc = 12.92 * lin if lin <= 0.0031308 else 1.055 * lin ** (1 / 2.4) - 0.055
        return round(enc * 255)

    return [ch(v) for v in c]


def helium(color):
    bar = color("Header", "BackgroundNormal")
    text = color("Window", "ForegroundNormal")
    view = color("View", "BackgroundNormal")
    view_text = color("View", "ForegroundNormal")
    inactive_tab = mix(bar, text, INACTIVE_TAB_MIX)

    # In Helium's compact layout the active tab and the toolbar segments on
    # either side share the toolbar color, so toolbar and frame must match
    # for the strip to read as one bar. Inactive tabs get the lighter Breeze
    # tab color, the way Dolphin draws them.
    colors = {
        "frame": bar,
        "frame_inactive": bar,
        "frame_incognito": bar,
        "frame_incognito_inactive": bar,
        "toolbar": bar,
        "background_tab": inactive_tab,
        "background_tab_inactive": inactive_tab,
        "tab_text": text,
        "tab_background_text": text,
        "tab_background_text_inactive": color("Window", "ForegroundInactive"),
        "toolbar_text": text,
        "toolbar_button_icon": text,
        "bookmark_text": text,
        "omnibox_background": view,
        "omnibox_text": view_text,
        "ntp_background": view,
        "ntp_text": view_text,
        "ntp_link": color("View", "ForegroundLink"),
    }
    return {k: kwin_compensate(v) for k, v in colors.items()}


def ansi(color):
    """The 16 terminal colors, shared by Ghostty and the VS Code terminal."""
    bg = color("View", "BackgroundNormal")
    fg = color("View", "ForegroundNormal")
    normal = [
        mix(bg, fg, 0.15),
        color("View", "ForegroundNegative"),
        color("View", "ForegroundPositive"),
        color("View", "ForegroundNeutral"),
        color("View", "ForegroundLink"),
        color("View", "ForegroundVisited"),
        CYAN,
        fg,
    ]
    bright = [
        mix(bg, fg, 0.45),
        *(mix(c, WHITE, 0.25) for c in normal[1:7]),
        mix(fg, WHITE, 0.6),
    ]
    return normal + bright


def ghostty(color):
    bg = color("View", "BackgroundNormal")
    fg = color("View", "ForegroundNormal")
    accent = color("Selection", "BackgroundNormal")
    accent_text = color("Selection", "ForegroundNormal")

    lines = [
        f"# Generated by darwin-breeze/build.py from {SCHEME.name}",
        f"background = {hexc(bg)}",
        f"foreground = {hexc(fg)}",
        f"cursor-color = {hexc(accent)}",
        f"cursor-text = {hexc(accent_text)}",
        f"selection-background = {hexc(accent)}",
        f"selection-foreground = {hexc(accent_text)}",
    ]
    lines += [f"palette = {i}={hexc(c)}" for i, c in enumerate(ansi(color))]
    return "\n".join(lines) + "\n"


def t3(color):
    """Every color slot of a T3 Code theme, mapped onto a scheme role."""
    window, window_text = color("Window", "BackgroundNormal"), color("Window", "ForegroundNormal")
    view, view_text = color("View", "BackgroundNormal"), color("View", "ForegroundNormal")
    header, header_text = color("Header", "BackgroundNormal"), color("Header", "ForegroundNormal")
    button, button_text = color("Button", "BackgroundNormal"), color("Button", "ForegroundNormal")
    accent, accent_text = color("Selection", "BackgroundNormal"), color("Selection", "ForegroundNormal")
    unfocused = color("Selection][Inactive", "BackgroundNormal")
    unfocused_text = color("Selection][Inactive", "ForegroundNormal")
    muted = color("View", "ForegroundInactive")
    negative = color("View", "ForegroundNegative")
    neutral = color("View", "ForegroundNeutral")
    link = color("View", "ForegroundLink")
    window_line = mix(window, window_text, 0.115)

    colors = {
        "canvas": view,
        "chrome": header,
        "toolbar": header,
        "toolbarForeground": header_text,
        "toolbarBorder": mix(header, header_text, 0.115),
        "toolbarControl": button,
        "toolbarControlForeground": button_text,
        "toolbarControlHover": color("Button", "BackgroundAlternate"),
        "surface": view,
        "surfaceRaised": window,
        "surfaceOverlay": window,
        "text": view_text,
        "textMuted": muted,
        "border": mix(view, view_text, 0.115),
        "input": mix(view, view_text, 0.3),
        "focus": mix(view, accent, 0.5),
        "accent": accent,
        "accentForeground": accent_text,
        "secondary": button,
        "secondaryForeground": button_text,
        "muted": window,
        "mutedForeground": color("Window", "ForegroundInactive"),
        "placeholder": muted,
        "secondaryLabel": muted,
        "iconMuted": muted,
        "error": negative,
        "errorForeground": negative,
        "errorSurface": mix(view, negative, 0.1),
        "warning": neutral,
        "warningForeground": neutral,
        "warningSurface": mix(view, neutral, 0.1),
        "update": link,
        "updateForeground": link,
        "updateSurface": mix(view, link, 0.12),
        "accentSurface": unfocused,
        "accentSurfaceForeground": unfocused_text,
        "messageSurface": window,
        "messageForeground": window_text,
        "messageAction": accent,
        "messageActionForeground": accent_text,
        "messageActionHover": color("Selection", "BackgroundAlternate"),
        "codeBackground": window,
        "codeForeground": WHITE,
        "searchMatchBackground": mix(view, YELLOW, 0.25),
        "searchMatchForeground": view_text,
        "searchMatchActiveBackground": YELLOW,
        "searchMatchActiveForeground": (0, 0, 0),
        "sidebar": window,
        "sidebarForeground": window_text,
        "sidebarMutedForeground": color("Window", "ForegroundInactive"),
        "sidebarControlSurface": button,
        "sidebarRowHover": window_line,
        "sidebarRowActive": unfocused,
        "sidebarRowSelected": unfocused,
        "sidebarBorder": window_line,
        "terminalBackground": view,
        "terminalForeground": WHITE,
        "terminalCursor": WHITE,
        "terminalSelection": mix(view, accent, 0.4),
        "terminalScrollbar": mix(view, view_text, 0.3),
        "terminalScrollbarHover": muted,
    }
    # T3 Code runs on Chromium too, so it needs the same KWin compensation.
    return {k: hexc(kwin_compensate(v)) for k, v in colors.items()}


def telegram(color):
    """Telegram keys mapped onto a scheme role; the rest come from night."""
    window, window_text = color("Window", "BackgroundNormal"), color("Window", "ForegroundNormal")
    view, view_text = color("View", "BackgroundNormal"), color("View", "ForegroundNormal")
    header, header_text = color("Header", "BackgroundNormal"), color("Header", "ForegroundNormal")
    title_inactive = color("Header][Inactive", "BackgroundNormal")
    title_inactive_text = color("Header][Inactive", "ForegroundNormal")
    tooltip, tooltip_text = color("Tooltip", "BackgroundNormal"), color("Tooltip", "ForegroundNormal")
    accent, accent_text = color("Selection", "BackgroundNormal"), color("Selection", "ForegroundNormal")
    accent_hover = color("Selection", "BackgroundAlternate")
    muted = color("Window", "ForegroundInactive")
    negative = color("Window", "ForegroundNegative")
    positive = color("Window", "ForegroundPositive")
    link = color("Window", "ForegroundLink")
    hover = mix(window, window_text, 0.115)
    ripple = mix(window, window_text, 0.18)
    control = mix(window, window_text, 0.3)
    msg_in = mix(view, view_text, 0.1)
    msg_out = mix(view, accent, 0.5)

    return {
        "windowBg": window,
        "windowFg": window_text,
        "windowBgOver": hover,
        "windowBgRipple": ripple,
        "windowFgOver": window_text,
        "windowSubTextFg": muted,
        "windowSubTextFgOver": mix(muted, window_text, 0.2),
        "windowBoldFg": window_text,
        "windowBoldFgOver": window_text,
        "windowBgActive": accent,
        "windowFgActive": accent_text,
        "windowActiveTextFg": link,
        "windowShadowFgFallback": window,
        "activeButtonBg": accent,
        "activeButtonBgOver": accent_hover,
        "activeButtonBgRipple": mix(accent, WHITE, 0.2),
        "activeButtonFg": accent_text,
        "activeButtonFgOver": accent_text,
        "activeButtonSecondaryFg": mix(accent, accent_text, 0.75),
        "activeLineFg": accent,
        "activeLineFgError": negative,
        "lightButtonBg": window,
        "lightButtonBgOver": mix(window, accent, 0.12),
        "lightButtonBgRipple": mix(window, accent, 0.2),
        "lightButtonFg": link,
        "attentionButtonFg": negative,
        "attentionButtonFgOver": negative,
        "attentionButtonBgOver": mix(window, negative, 0.12),
        "attentionButtonBgRipple": mix(window, negative, 0.2),
        "outlineButtonOutlineFg": accent,
        "menuBg": window,
        "menuBgOver": hover,
        "menuBgRipple": ripple,
        "menuIconFg": muted,
        "menuIconFgOver": mix(muted, window_text, 0.3),
        "menuSubmenuArrowFg": muted,
        "menuFgDisabled": control,
        "menuSeparatorFg": hover,
        "checkboxFg": muted,
        "sliderBgInactive": control,
        "sliderBgActive": accent,
        "inputBorderFg": control,
        # Breeze draws text fields in the view color with a blue focus ring.
        "filterInputActiveBg": view,
        "filterInputInactiveBg": view,
        "filterInputBorderFg": accent,
        "tooltipBg": tooltip,
        "tooltipFg": tooltip_text,
        "tooltipBorderFg": mix(tooltip, tooltip_text, 0.115),
        "titleBg": title_inactive,
        "titleBgActive": header,
        "titleFg": title_inactive_text,
        "titleFgActive": header_text,
        "topBarBg": header,
        "boxBg": window,
        "boxTitleFg": window_text,
        "boxTextFgGood": positive,
        "boxTextFgError": negative,
        # Folder strip in the view color, so the selected folder merges into
        # the chat list next to it.
        "sideBarBg": view,
        "sideBarBgActive": window,
        "sideBarBgRipple": mix(view, window_text, 0.1),
        "sideBarTextFg": muted,
        "sideBarTextFgActive": link,
        "sideBarIconFg": muted,
        "sideBarIconFgActive": link,
        "sideBarBadgeBg": accent,
        "sideBarBadgeBgMuted": control,
        "sideBarBadgeFg": accent_text,
        "dialogsBg": window,
        "dialogsBgOver": hover,
        "dialogsRippleBg": ripple,
        "dialogsBgActive": accent,
        "dialogsRippleBgActive": accent_hover,
        "dialogsNameFg": window_text,
        "dialogsTextFg": muted,
        "dialogsTextFgOver": muted,
        "dialogsTextFgService": link,
        "dialogsTextFgServiceOver": link,
        "dialogsDateFg": muted,
        "dialogsDateFgOver": muted,
        "dialogsDraftFg": negative,
        "dialogsOnlineBadgeFg": positive,
        "dialogsVerifiedIconBg": link,
        "dialogsVerifiedIconFg": window,
        "dialogsUnreadBg": accent,
        "dialogsUnreadBgOver": accent,
        "dialogsUnreadFg": accent_text,
        "dialogsUnreadBgMuted": control,
        "dialogsUnreadBgMutedOver": mix(window, window_text, 0.35),
        "dialogsUnreadBgActive": accent_text,
        "dialogsUnreadFgActive": accent,
        "dialogsUnreadBgMutedActive": mix(accent, accent_text, 0.55),
        "historyComposeAreaBg": window,
        "historyComposeAreaFg": window_text,
        "historyComposeButtonBgOver": hover,
        "historyComposeButtonBgRipple": ripple,
        "historyTextInFg": view_text,
        "historyTextOutFg": view_text,
        "historyLinkInFg": link,
        "msgInBg": msg_in,
        "msgInBgSelected": mix(msg_in, accent, 0.3),
        "msgOutBg": msg_out,
        "msgOutBgSelected": mix(msg_out, accent, 0.3),
        "msgInDateFg": muted,
        "msgOutDateFg": mix(msg_out, WHITE, 0.55),
        "msgSelectOverlay": (*accent, 0x4C),
        "msgStickerOverlay": (*accent, 0x7F),
    }


def luma(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def interp(points, x):
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        if x <= x1:
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return points[-1][1]


def parse_hex(v):
    h = v[1:]
    if len(h) in (3, 4):
        h = "".join(ch * 2 for ch in h)
    return tuple(int(h[i:i + 2], 16) for i in range(0, len(h), 2))


def telegram_theme(color):
    """The night theme, recolored onto the scheme.

    Night tints everything blue. Its tinted grays become scheme grays of
    matching brightness, its blues take the accent's hue and saturation, and
    other hues (reds, greens, name colors) stay. telegram() then pins every
    key that has a scheme role.
    """
    base = TELEGRAM_BASE.read_text()
    line_re = re.compile(r"^(\w+):\s*(#[0-9a-fA-F]+)\s*;")
    night = {m[1]: parse_hex(m[2]) for m in map(line_re.match, base.splitlines()) if m}

    window, muted = color("Window", "BackgroundNormal"), color("Window", "ForegroundInactive")
    grays = sorted({
        (0, 0),
        (luma(night["windowBg"]), window[0]),
        (luma(night["windowSubTextFg"]), muted[0]),
        (255, 255),
    })
    accent_h, _, accent_s = colorsys.rgb_to_hls(*(v / 255 for v in color("Selection", "BackgroundNormal")))

    def recolor(c):
        rgb, alpha = c[:3], c[3:]
        chroma = max(rgb) - min(rgb)
        h, l, _ = colorsys.rgb_to_hls(*(v / 255 for v in rgb))
        if chroma <= 4 or not 195 <= h * 360 <= 225:
            return c
        if chroma <= 55:
            g = round(interp(grays, luma(rgb)))
            return (g, g, g, *alpha)
        return (*(round(v * 255) for v in colorsys.hls_to_rgb(accent_h, l, accent_s)), *alpha)

    pinned = telegram(color)
    seen = set()
    out = [f"// Generated by darwin-breeze/build.py from {SCHEME.name}"]
    for line in base.splitlines():
        m = line_re.match(line)
        if m:
            key = m[1]
            seen.add(key)
            c = pinned[key] if key in pinned else recolor(night[key])
            line = f"{key}: {hexc(c)};" + line[m.end():]
        elif re.match(r"^(\w+):", line) and line.split(":")[0] in pinned:
            key = line.split(":")[0]
            seen.add(key)
            line = f"{key}: {hexc(pinned[key])};"
        out.append(line)
    out += [f"{k}: {hexc(c)};" for k, c in pinned.items() if k not in seen]
    return "\n".join(out) + "\n"


def vscode_base_colors():
    """Dark 2026's colors with its include chain resolved."""
    chain, path = [], VSCODE_UI
    while path:
        theme = json.loads(path.read_text())
        chain.append(theme.get("colors", {}))
        path = path.parent / theme["include"] if "include" in theme else None
    colors = {}
    for layer in reversed(chain):
        colors.update(layer)
    return {k: parse_hex(v) for k, v in colors.items()}


def vscode(color):
    """Workbench colors: Dark 2026, recolored onto the scheme.

    Dark 2026 lays out its grays the way the scheme does: the chrome lighter
    than the editor, widgets lighter still. Each of those grays becomes the
    scheme gray in the same place, and the grays in between are interpolated.
    Each hue takes the hue of the matching scheme color but keeps its own
    lightness and saturation, so a muted dark red background stays one. pins
    then sets the keys that have an exact scheme role, which is where the full
    macOS blue shows.
    """
    window, window_text = color("Window", "BackgroundNormal"), color("Window", "ForegroundNormal")
    view, view_text = color("View", "BackgroundNormal"), color("View", "ForegroundNormal")
    accent, accent_text = color("Selection", "BackgroundNormal"), color("Selection", "ForegroundNormal")
    muted = color("Window", "ForegroundInactive")
    negative = color("View", "ForegroundNegative")
    neutral = color("View", "ForegroundNeutral")
    positive = color("View", "ForegroundPositive")
    link = color("View", "ForegroundLink")
    base = vscode_base_colors()

    grays = sorted({
        (0, 0),
        (luma(base["editor.background"]), view[0]),
        (luma(base["sideBar.background"]), window[0]),
        (luma(base["editorWidget.background"]), color("Window", "BackgroundAlternate")[0]),
        (luma(base["sideBar.border"]), mix(window, window_text, 0.115)[0]),
        (luma(base["descriptionForeground"]), muted[0]),
        (luma(base["foreground"]), window_text[0]),
        (255, 255),
    })
    assert all(a[1] <= b[1] for a, b in zip(grays, grays[1:])), grays

    def hls(c):
        return colorsys.rgb_to_hls(*(v / 255 for v in c))

    # (hue range in degrees, scheme color whose hue it takes)
    families = [
        ((0, 15), negative),
        ((15, 70), neutral),
        ((70, 170), positive),
        ((170, 250), accent),
        ((250, 330), color("View", "ForegroundVisited")),
        ((330, 360), negative),
    ]

    def recolor(c):
        rgb, alpha = c[:3], c[3:]
        if max(rgb) - min(rgb) <= 10:
            g = round(interp(grays, luma(rgb)))
            return (g, g, g, *alpha)
        h, l, sat = hls(rgb)
        target = next(t for (lo, hi), t in families if lo <= h * 360 < hi)
        return (*(round(v * 255) for v in colorsys.hls_to_rgb(hls(target)[0], l, sat)), *alpha)

    pins = {
        "editor.background": view,
        "editor.foreground": view_text,
        "titleBar.inactiveBackground": color("Header][Inactive", "BackgroundNormal"),
        "titleBar.inactiveForeground": color("Header][Inactive", "ForegroundNormal"),
        "focusBorder": (*accent, 0xB3),
        "quickInputList.focusBackground": accent,
        "button.background": accent,
        "button.border": accent,
        "button.hoverBackground": color("Selection", "BackgroundAlternate"),
        "button.foreground": accent_text,
        "badge.background": accent,
        "badge.foreground": accent_text,
        "activityBarBadge.background": accent,
        "activityBarBadge.foreground": accent_text,
        "tab.activeBorderTop": accent,
        "panelTitle.activeBorder": accent,
        "textLink.foreground": link,
        "textLink.activeForeground": link,
    }
    names = ["Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"]
    for i, c in enumerate(ansi(color)):
        pins[f"terminal.ansi{'Bright' if i >= 8 else ''}{names[i % 8]}"] = c

    colors = {k: pins.get(k) or recolor(c) for k, c in base.items()}
    colors.update(pins)
    # Electron is Chromium, so it needs the same KWin compensation as Helium.
    return {k: hexc(kwin_compensate(c[:3]) + list(c[3:])) for k, c in sorted(colors.items())}


def vscode_files(color):
    """The extension files, keyed by their path inside it."""
    name = "Darwin Breeze Dark"
    # Syntax colors as T3 Code shows them. T3 Code doesn't compensate them
    # either, so the two render the same.
    syntax = json.loads(VSCODE_SYNTAX.read_text())
    theme = {
        "$schema": "vscode://schemas/color-theme",
        "name": name,
        "type": "dark",
        "semanticHighlighting": True,
        "colors": vscode(color),
        "tokenColors": syntax["tokenColors"],
        "semanticTokenColors": syntax["semanticTokenColors"],
    }
    package = {
        "name": "darwin-breeze",
        "displayName": "Darwin Breeze",
        "description": f"Generated by darwin-breeze/build.py from {SCHEME.name}",
        "publisher": "trivk",
        "version": "1.0.0",
        "engines": {"vscode": "^1.70.0"},
        "categories": ["Themes"],
        "contributes": {
            "themes": [{"label": name, "uiTheme": "vs-dark", "path": f"./{VSCODE_THEME}"}],
        },
    }
    return {
        "package.json": json.dumps(package, indent=2) + "\n",
        VSCODE_THEME: json.dumps(theme, indent=2) + "\n",
    }


def vsix(files):
    """Pack the extension the way vsce does, for code --install-extension."""
    manifest = """<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011" xmlns:d="http://schemas.microsoft.com/developer/vsx-schema-design/2011">
  <Metadata>
    <Identity Language="en-US" Id="darwin-breeze" Version="1.0.0" Publisher="trivk"/>
    <DisplayName>Darwin Breeze</DisplayName>
    <Description xml:space="preserve">Darwin Breeze Dark color theme</Description>
    <Categories>Themes</Categories>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="^1.70.0"/>
    </Properties>
  </Metadata>
  <Installation>
    <InstallationTarget Id="Microsoft.VisualStudio.Code"/>
  </Installation>
  <Dependencies/>
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/>
  </Assets>
</PackageManifest>
"""
    content_types = """<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension=".json" ContentType="application/json"/><Default Extension=".vsixmanifest" ContentType="text/xml"/></Types>
"""
    return zip_bytes({
        "[Content_Types].xml": content_types,
        "extension.vsixmanifest": manifest,
        **{f"extension/{path}": text for path, text in files.items()},
    })


def solid_png(c):
    """A 1x1 PNG; Telegram stretches it over the chat as a plain background."""

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))

    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(bytes([0, *c])))
        + chunk(b"IEND", b"")
    )


def zip_bytes(files):
    """A zip with fixed timestamps, so an unchanged theme rebuilds byte-identical."""
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as z:
        for name, data in files.items():
            info = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            z.writestr(info, data)
    return buf.getvalue()


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(data, str):
        data = data.encode()
    if path.exists() and path.read_bytes() == data:
        return False
    path.write_bytes(data)
    print(f"wrote {path.relative_to(PKG)}")
    return True


def main():
    color = load()
    manifest = {
        "manifest_version": 3,
        "name": "Darwin Breeze",
        "version": "1.0",
        "description": f"Generated by darwin-breeze/build.py from {SCHEME.name}",
        "theme": {"colors": helium(color)},
    }
    if write(HELIUM / "manifest.json", json.dumps(manifest, indent=2) + "\n"):
        # Helium would keep showing the old colors from its cache.
        (HELIUM / "Cached Theme.pak").unlink(missing_ok=True)

    write(GHOSTTY, ghostty(color))

    theme = {"version": 1, "name": "Darwin Breeze", "appearance": "dark", "colors": t3(color)}
    write(T3, json.dumps(theme, indent=2) + "\n")

    write(TELEGRAM, zip_bytes({
        "colors.tdesktop-theme": telegram_theme(color),
        "background.png": solid_png(color("View", "BackgroundNormal")),
    }))

    files = vscode_files(color)
    for path, text in files.items():
        write(VSCODE / path, text)
    write(VSCODE / "darwin-breeze.vsix", vsix(files))


if __name__ == "__main__":
    main()
