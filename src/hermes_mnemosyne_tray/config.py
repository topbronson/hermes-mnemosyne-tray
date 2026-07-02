"""hermes-mnemosyne-tray: tray indicator for the Mnemosyne memory dashboard.

The Mnemosyne dashboard is a standalone web server (the
``mnemosyne-dashboard`` plugin's ``server.py``) that runs on its own
port — by default 8765. It is *not* part of the unified
``hermes dashboard``; it's a separate process that you start
explicitly (or that the dashboard's "Start Mnemosyne Dashboard" button
starts on your behalf).

This indicator supervises that process. Start/Stop/Restart menu items
work via ``subprocess.Popen``/``pkill``, just like
``hermes-dashboard-tray`` does for the main dashboard.

This is a thin wrapper around the shared :mod:`hermes_tray` library.
It supplies the Mnemosyne-specific :class:`Config` and a
:class:`PortListeningProbe`, then delegates everything else to the library.
"""
from __future__ import annotations

from pathlib import Path

from hermes_tray import Config

__all__ = ["make_config"]


def make_config() -> Config:
    """Build the :class:`Config` for the Mnemosyne dashboard indicator.

    The dashboard server lives at
    ``~/.hermes/plugins/mnemosyne-dashboard/server.py`` and accepts
    ``--host`` and ``--port`` flags. Default is ``0.0.0.0:8765``; the
    install script's host detection overrides this with your Tailscale
    IP. The ``HERMES_MNEMOSYNE_PORT`` env var lets you retarget.

    The DB path is also configurable; the plugin defaults to
    ``~/.hermes/mnemosyne/data/mnemosyne.db``. We pass the default
    explicitly here so the indicator's Start command works even when
    the dashboard config file doesn't exist yet.
    """
    return Config(
        name="mnemosyne",
        title="Mnemosyne",
        # Run the plugin's server.py directly — no `hermes` CLI subcommand
        # exists for this. The lib appends --host HOST --port PORT after
        # our subcommand, so we just need to put --db first.
        bin="python3",
        subcommand=(
            "/home/top-bronson/.hermes/plugins/mnemosyne-dashboard/server.py",
            "--db",
            "/home/top-bronson/.hermes/mnemosyne/data/mnemosyne.db",
        ),
        host="localhost",
        port=8765,
        url="http://localhost:8765",
        icon_dir=Path("~/.local/share/icons/hicolor/256x256/apps").expanduser(),
        icon_fallback="hermes-mnemosyne-circle-64.png",
        cwd="/home/top-bronson/.hermes/plugins/mnemosyne-dashboard",
    )
