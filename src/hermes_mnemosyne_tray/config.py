"""hermes-mnemosyne-tray: tray indicator for the Mnemosyne dashboard.

This is a thin wrapper around the shared :mod:`hermes_tray` library. It
supplies the Mnemosyne-specific :class:`Config` and a port-listening
:class:`LivenessProbe`, then delegates everything else to the library.
"""

from __future__ import annotations

from pathlib import Path

from hermes_tray import Config

__all__ = ["make_config"]


def make_config() -> Config:
    """Build the :class:`Config` for the Mnemosyne dashboard indicator.

    The defaults assume the user's Mnemosyne plugin is configured to bind
    to a Tailscale IP via ``~/.hermes/config.yaml``; the host is then
    injected by the install script's systemd unit. The
    ``HERMES_MNEMOSYNE_HOST`` env var takes precedence.
    """
    return Config(
        name="mnemosyne",
        title="Mnemosyne",
        bin="hermes",
        subcommand=("mnemosyne", "dashboard", "start"),
        host="localhost",
        port=8765,
        url="http://localhost:8765",
        icon_dir=Path("~/.local/share/icons/hicolor/256x256/apps").expanduser(),
        icon_fallback="hermes-mnemosyne-circle-64.png",
        cwd="~",
    )
