#!/usr/bin/env bash
# Download the Mnemosyne mosaic source image from Wikimedia Commons (CC0).
# Idempotent: exits 0 immediately if the image already exists locally.

set -euo pipefail
DEST="$(cd "$(dirname "$0")/.." && pwd)/share/icons/source/mnemosyne-mosaic.jpg"
mkdir -p "$(dirname "$DEST")"
if [[ -f "$DEST" ]]; then
    echo "already have $DEST"
    exit 0
fi
curl -fL --user-agent "hermes-mnemosyne-tray/0.1 (github.com/topbronson)" \
    -o "$DEST" \
    "https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/Mosa%C3%AFque_murale_Mn%C3%A9mosyne.jpg/1280px-Mosa%C3%AFque_murale_Mn%C3%A9mosyne.jpg"
echo "wrote $DEST"
