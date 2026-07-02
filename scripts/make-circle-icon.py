#!/usr/bin/env python3
"""Generate the circular tray icon variants from the Mnemosyne mosaic source.

Source: ``share/icons/source/mnemosyne-mosaic.jpg`` (CC0, downloaded by
``fetch-source.sh`` on demand).

Outputs:
    ~/.local/share/icons/hicolor/256x256/apps/hermes-mnemosyne-circle-*.png
    ~/.local/share/icons/hicolor/scalable/apps/hermes-mnemosyne-circle.svg

Re-run this when the source logo changes.
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
SVG_DIR = ICON_DIR.parent / "scalable" / "apps"
ICON_DIR.mkdir(parents=True, exist_ok=True)
SVG_DIR.mkdir(parents=True, exist_ok=True)

SIZES = [32, 48, 64, 96, 128, 256]


def make_circular(img: Image.Image, size: int) -> Image.Image:
    """Resize ``img`` to ``size`` and apply a circular mask."""
    base = img.resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)
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
    # Center-crop to square
    w, h = img.size
    side = min(w, h)
    img = img.crop(
        ((w - side) // 2, (h - side) // 2, (w + side) // 2, (h + side) // 2)
    )

    for size in SIZES:
        out_path = ICON_DIR / f"hermes-mnemosyne-circle-{size}.png"
        make_circular(img, size).save(out_path, "PNG")
        print(f"wrote {out_path}")

    # Canonical 256px
    canon = ICON_DIR / "hermes-mnemosyne-circle.png"
    make_circular(img, 256).save(canon, "PNG")
    print(f"wrote {canon}")

    # SVG (a 256x256 PNG inlined into an SVG container; still scales)
    import base64

    svg_path = SVG_DIR / "hermes-mnemosyne-circle.svg"
    png_path = ICON_DIR / "hermes-mnemosyne-circle-256.png"
    with png_path.open("rb") as fh:
        b64 = base64.b64encode(fh.read()).decode("ascii")
    svg = (
        f'<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" '
        f'viewBox="0 0 256 256">\n'
        f'  <image width="256" height="256" '
        f'href="data:image/png;base64,{b64}"/>\n'
        f'</svg>\n'
    )
    with svg_path.open("w") as fh:
        fh.write(svg)
    print(f"wrote {svg_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
