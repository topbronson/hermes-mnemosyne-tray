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

# Pick the Python interpreter that has hermes-tray-lib + the indicator
# package importable. We check the same three places the indicator
# detection below uses; this single value drives both EXEC_LINE (for
# the .desktop and systemd units) and the wrapper-shim shebang.
# We use `readlink -e` (which returns nothing if the path doesn't resolve
# to an existing file) so we don't get tricked by a broken self-symlink
# left over from a previous failed install.
INDICATOR_PY=""
if [[ -n "$(readlink -e "$HOME/.local/bin/hermes-mnemosyne-indicator" 2>/dev/null)" ]]; then
    # pip install --user → use system python (which has the package)
    INDICATOR_PY="/usr/bin/python3"
elif [[ -n "$(readlink -e "$REPO_ROOT/.venv/bin/hermes-mnemosyne-indicator" 2>/dev/null)" ]]; then
    INDICATOR_PY="$REPO_ROOT/.venv/bin/python3"
elif [[ -x "$REPO_ROOT/.venv/bin/python3" ]]; then
    INDICATOR_PY="$REPO_ROOT/.venv/bin/python3"
else
    # No venv and no pip install — fall back to the system python. The
    # wrapper shim (created later) will only work if the user has
    # hermes-tray-lib system-wide, which is rare. They'll see a clear
    # error at first start if it's missing.
    INDICATOR_PY="/usr/bin/python3"
fi

EXEC_LINE="$INDICATOR_PY $BIN_DIR/hermes-mnemosyne-indicator"
if [[ -n "$HERMES_BIN_PATH" && "$HERMES_BIN_PATH" != "$PREFIX/bin/hermes" ]]; then
    EXEC_LINE="/usr/bin/env HERMES_MNEMOSYNE_BIN=${HERMES_BIN_PATH} $EXEC_LINE"
fi

# -----------------------------------------------------------------------------
# Auto-detect HERMES_MNEMOSYNE_HOST
# -----------------------------------------------------------------------------
# The Mnemosyne dashboard plugin in ~/.hermes/config.yaml is the source of
# truth. If that doesn't have a `host:` line, fall back to the user's
# Tailscale IPv4 address (`tailscale ip -4` is the canonical source for
# that). Final fallback: localhost.
DETECTED_MNEMOSYNE_HOST="$(grep -E '^\s*host:' "$HOME/.hermes/config.yaml" 2>/dev/null \
    | head -1 | awk -F: '{print $2}' | tr -d ' "' || true)"
if [[ -z "$DETECTED_MNEMOSYNE_HOST" ]]; then
    DETECTED_MNEMOSYNE_HOST="$(tailscale ip -4 2>/dev/null | head -1 || true)"
fi
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

# Locate the indicator console-script. Check three places, in order:
#   1. ~/.local/bin/        (the `pip install --user` location)
#   2. <REPO>/.venv/bin/    (the python -m venv install location)
#   3. None — fall back to a wrapper shim that uses $INDICATOR_PY
#      (chosen above) to run the indicator directly from the repo source.
#      This makes ./install.sh work without a `pip install --user` step
#      on systems where pip is unavailable (Ubuntu 24.04+ ships
#      without pip by default).
#
# We use `readlink -e` (which returns nothing if the path doesn't resolve
# to an existing file) so we don't get tricked by a broken self-symlink
# left over from a previous failed install.
INDICATOR_BIN=""
if [[ -n "$(readlink -e "$HOME/.local/bin/hermes-mnemosyne-indicator" 2>/dev/null)" ]]; then
    INDICATOR_BIN="$HOME/.local/bin/hermes-mnemosyne-indicator"
elif [[ -n "$(readlink -e "$REPO_ROOT/.venv/bin/hermes-mnemosyne-indicator" 2>/dev/null)" ]]; then
    INDICATOR_BIN="$REPO_ROOT/.venv/bin/hermes-mnemosyne-indicator"
fi

if [[ -n "$INDICATOR_BIN" ]]; then
    # Only create the symlink if the source is actually somewhere different
    # from the destination. If both are ~/.local/bin/hermes-...-indicator
    # (the pip --user case with default PREFIX), `ln -sf A A` would
    # create a self-referencing symlink that systemd then fails to open.
    if [[ "$(readlink -f "$INDICATOR_BIN" 2>/dev/null || echo "$INDICATOR_BIN")" \
            != "$(readlink -f "$BIN_DIR/hermes-mnemosyne-indicator" 2>/dev/null || echo "$BIN_DIR/hermes-mnemosyne-indicator")" ]]; then
        ln -sf "$INDICATOR_BIN" "$BIN_DIR/hermes-mnemosyne-indicator"
    fi
else
    # Create a wrapper shim that invokes the module directly.
    cat > "$BIN_DIR/hermes-mnemosyne-indicator" <<PYEOF
#!/usr/bin/env python3
"""Auto-generated shim - runs the Mnemosyne indicator from $REPO_ROOT.

Uses the python interpreter that has hermes-tray-lib on the path; this
is the venv's python if a venv was created, else the system python
(which only works if hermes-tray-lib is system-wide installable).
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path("$REPO_ROOT") / "src"))
from hermes_mnemosyne_tray.__main__ import main
sys.exit(main())
PYEOF
    chmod +x "$BIN_DIR/hermes-mnemosyne-indicator"
    echo "Created wrapper shim at $BIN_DIR/hermes-mnemosyne-indicator"
    echo "(no console script found; shim uses $INDICATOR_PY from repo source)"
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
