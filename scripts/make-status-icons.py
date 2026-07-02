#!/usr/bin/env python3
"""Generate per-state tray icon variants from the circular base icon.

Each state: the circular logo on a transparent background, with a small
colored dot in the bottom-right corner to indicate status.

States:
    running   - green dot
    starting  - yellow dot
    stopped   - grey dot
    error     - red dot

Source: ``share/icons/source/mnemosyne-mosaic.jpg`` (or override via
``HERMES_MNEMOSYNE_LOGO_SOURCE``).

Outputs: ``~/.local/share/icons/hicolor/256x256/apps/hermes-mnemosyne-{state}-{size}.png``
"""
from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SOURCE = REPO_ROOT / "share" / "icons" / "source" / "mnemosyne-mosaic.jpg"

SOURCE = Path(os.environ.get("HERMES_MNEMOSYNE_LOGO_SOURCE", str(DEFAULT_SOURCE)))
ICON_DIR = Path(
    os.environ.get(
        "HERMES_MNEMOSYNE_ICON_DIR",
        str(Path("~/.local/share/icons/hicolor/256x256/apps").expanduser()),
    )
)
ICON_DIR.mkdir(parents=True, exist_ok=True)

DOT_COLORS = {
    "running": (60, 162, 60, 255),  # green
    "starting": (220, 180, 40, 255),  # yellow
    "stopped": (140, 140, 140, 255),  # grey
    "error": (200, 50, 50, 255),  # red
}

SIZES = [32, 48, 64, 96, 128, 256]
STATES = ["running", "starting", "stopped", "error"]


def render(logo: Image.Image, state: str, size: int) -> Image.Image:
    """Build a ``size``-pixel icon for ``state`` with a status-dot overlay."""
    base = logo.resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)

    color = DOT_COLORS[state]
    dot_r = max(6, size // 8)
    halo_r = dot_r + max(1, size // 32)
    cx = cy = size - dot_r - 1
    draw = ImageDraw.Draw(out)
    draw.ellipse(
        (cx - halo_r, cy - halo_r, cx + halo_r, cy + halo_r),
        fill=(255, 255, 255, 255),
    )
    draw.ellipse(
        (cx - dot_r, cy - dot_r, cx + dot_r, cy + dot_r), fill=color
    )
    return out


def ensure_source() -> Path:
    """Run ``fetch-source.sh`` if the source image is missing."""
    if SOURCE.exists():
        return SOURCE
    script = REPO_ROOT / "scripts" / "fetch-source.sh"
    if script.exists():
        import subprocess

        subprocess.run([str(script)], check=True)
    if not SOURCE.exists():
        msg = f"source image not found: {SOURCE}\n"
        msg += "Run scripts/fetch-source.sh or set HERMES_MNEMOSYNE_LOGO_SOURCE."
        raise FileNotFoundError(msg)
    return SOURCE


def main() -> int:
    src = ensure_source()
    img = Image.open(src).convert("RGBA")
    w, h = img.size
    side = min(w, h)
    img = img.crop(
        ((w - side) // 2, (h - side) // 2, (w + side) // 2, (h + side) // 2)
    )

    for state in STATES:
        for size in SIZES:
            out = ICON_DIR / f"hermes-mnemosyne-{state}-{size}.png"
            render(img, state, size).save(out, "PNG")
            print(f"wrote {out}")
        # canonical 64px at default AppIndicator size
        canon = ICON_DIR / f"hermes-mnemosyne-{state}.png"
        render(img, state, 64).save(canon, "PNG")
        print(f"wrote {canon}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
