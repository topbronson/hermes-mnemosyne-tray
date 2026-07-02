#!/usr/bin/env bash
# Install the Hermes Mnemosyne tray indicator.
#
# Usage:
#   ./install.sh                       # install to ~/.local (default)
#   PREFIX=/usr/local ./install.sh     # install to /usr/local
#   HERMES_MNEMOSYNE_HOST=100.x.x.x ./install.sh   # override detected host
#
# Re-running is safe; existing files are overwritten in place.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
BIN_DIR="$PREFIX/bin"
SHARE_DIR="$PREFIX/share"
APPS_DIR="$SHARE_DIR/applications"
AUTOSTART_DIR="$SHARE_DIR/autostart"
ICON_DIR="$SHARE_DIR/icons/hicolor/256x256/apps"
SVG_DIR="$SHARE_DIR/icons/hicolor/scalable/apps"

# Resolve the hermes binary path for HERMES_MNEMOSYNE_BIN injection
HERMES_BIN_PATH="$(command -v hermes || true)"
EXEC_LINE="/usr/bin/python3 $BIN_DIR/hermes-mnemosyne-indicator"
if [[ -n "$HERMES_BIN_PATH" && "$HERMES_BIN_PATH" != "$PREFIX/bin/hermes" ]]; then
    EXEC_LINE="/usr/bin/env HERMES_MNEMOSYNE_BIN=${HERMES_BIN_PATH} $EXEC_LINE"
fi

# -----------------------------------------------------------------------------
# Auto-detect HERMES_MNEMOSYNE_HOST
# -----------------------------------------------------------------------------
# The Mnemosyne dashboard plugin in ~/.hermes/config.yaml is the source of
# truth. Read the `host:` setting (which is normally your Tailscale IP).
# Falls back to the env var, then to "localhost".
DETECTED_MNEMOSYNE_HOST="$(grep -E '^\s*host:' "$HOME/.hermes/config.yaml" 2>/dev/null \
    | head -1 | awk -F: '{print $2}' | tr -d ' "' || true)"
HERMES_MNEMOSYNE_HOST="${HERMES_MNEMOSYNE_HOST:-${DETECTED_MNEMOSYNE_HOST:-localhost}}"
echo "Mnemosyne host: $HERMES_MNEMOSYNE_HOST"

# -----------------------------------------------------------------------------
# Detect hermes-gateway.service
# -----------------------------------------------------------------------------
# If present, we want the indicator to start *after* it (and stop with it).
# Otherwise fall back to default.target (every login).
if [[ -f "$HOME/.config/systemd/user/hermes-gateway.service" ]]; then
    WANTED_BY="hermes-gateway.service"
    SYSTEMD_WANTS_DIR="$SYSTEMD_USER_DIR/hermes-gateway.service.wants"
    echo "Detected hermes-gateway.service — indicator will start alongside it."
else
    WANTED_BY="default.target"
    SYSTEMD_WANTS_DIR="$SYSTEMD_USER_DIR/default.target.wants"
    echo "No hermes-gateway.service found — indicator will start at every login."
fi

echo
echo "Installing to PREFIX=$PREFIX"
echo "  bin:        $BIN_DIR"
echo "  apps:       $APPS_DIR"
echo "  autostart:  $AUTOSTART_DIR"
echo "  icons:      $ICON_DIR"
echo "  systemd:    $SYSTEMD_USER_DIR/hermes-mnemosyne-indicator.service"

mkdir -p "$BIN_DIR" "$APPS_DIR" "$AUTOSTART_DIR" "$ICON_DIR" "$SVG_DIR" "$SYSTEMD_WANTS_DIR"

# Copy the indicator console-script (installed by `pip install --user`)
# If the user hasn't pip-installed yet, fall back to running the module directly.
if [[ -x "$HOME/.local/bin/hermes-mnemosyne-indicator" ]]; then
    ln -sf "$HOME/.local/bin/hermes-mnemosyne-indicator" "$BIN_DIR/hermes-mnemosyne-indicator"
else
    echo "Warning: hermes-mnemosyne-indicator not found in ~/.local/bin"
    echo "         (run 'pip install --user -e .' in the repo first)"
fi

# Render .desktop templates
sed "s|__EXEC_LINE__|$EXEC_LINE|g" \
    "$REPO_ROOT/share/applications/hermes-mnemosyne.desktop.in" \
    > "$APPS_DIR/hermes-mnemosyne.desktop"

sed "s|__EXEC_LINE__|$EXEC_LINE|g" \
    "$REPO_ROOT/share/autostart/hermes-mnemosyne-autostart.desktop.in" \
    > "$AUTOSTART_DIR/hermes-mnemosyne-autostart.desktop"

# Render and install systemd service
sed \
    -e "s|__EXEC_LINE__|$EXEC_LINE|g" \
    -e "s|__HERMES_MNEMOSYNE_HOST__|$HERMES_MNEMOSYNE_HOST|g" \
    -e "s|__WANTED_BY__|$WANTED_BY|g" \
    "$REPO_ROOT/share/systemd/hermes-mnemosyne-indicator.service.in" \
    > "$SYSTEMD_USER_DIR/hermes-mnemosyne-indicator.service"

# Symlink into the WantedBy target
ln -sf "$SYSTEMD_USER_DIR/hermes-mnemosyne-indicator.service" \
    "$SYSTEMD_WANTS_DIR/hermes-mnemosyne-indicator.service"

# Copy icons (skip if not yet generated — user regenerates later)
cp -n "$ICON_DIR"/hermes-mnemosyne-*.png "$ICON_DIR/" 2>/dev/null || true
cp -n "$SVG_DIR"/hermes-mnemosyne-*.svg "$SVG_DIR/" 2>/dev/null || true

# Refresh caches (best-effort)
command -v update-desktop-database >/dev/null && \
    update-desktop-database "$APPS_DIR" 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null && \
    gtk-update-icon-cache -f -t "$SHARE_DIR/icons/hicolor" 2>/dev/null || true

echo
echo "Installed."
echo
echo "Next steps:"
if [[ -d "$HOME/.config/systemd/user" ]]; then
    echo "  1. Reload systemd:    systemctl --user daemon-reload"
    echo "  2. Enable & start:    systemctl --user enable --now hermes-mnemosyne-indicator.service"
    echo
    echo "  To check status:      systemctl --user status hermes-mnemosyne-indicator.service"
    echo "  To view logs:         journalctl --user -u hermes-mnemosyne-indicator -f"
fi
echo "  - If icons are missing, regenerate them:"
echo "      cd $REPO_ROOT"
echo "      ./scripts/fetch-source.sh"
echo "      python3 scripts/make-circle-icon.py"
echo "      python3 scripts/make-status-icons.py"
