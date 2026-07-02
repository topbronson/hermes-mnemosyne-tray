"""hermes-mnemosyne-tray: tray indicator for the Mnemosyne memory dashboard.

The Mnemosyne dashboard is integrated into the unified ``hermes dashboard``
server (the one served on port 9119 by default). It is *not* a separate
process; it's a plugin that lives inside the running dashboard.

So this indicator supervises the unified dashboard's port, just like
``hermes-dashboard-tray`` does — but the menu and tooltip are
Mnemosyne-flavored, and the "Open Mnemosyne" URL points at the Mnemosyne
section of the dashboard.

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

    The Mnemosyne plugin lives inside the unified ``hermes dashboard``
    server, so the probe targets the same port the regular dashboard
    indicator uses (9119 by default). The ``HERMES_MNEMOSYNE_PORT`` env
    var lets you retarget if you've moved the unified dashboard.

    ``auto_start`` is False because there is no separate Mnemosyne
    process to start — the Mnemosyne plugin is part of the running
    ``hermes dashboard``. Use ``hermes-dashboard-tray`` to start the
    parent process.
    """
    return Config(
        name="mnemosyne",
        title="Mnemosyne",
        bin="hermes",
        # The Mnemosyne plugin is served by the unified `hermes dashboard`
        # command; that's what we open and what the liveness probe checks.
        # We don't auto-start it here — `hermes-dashboard-tray` owns that.
        subcommand=("dashboard",),
        host="localhost",
        port=9119,
        url="http://localhost:9119",
        icon_dir=Path("~/.local/share/icons/hicolor/256x256/apps").expanduser(),
        icon_fallback="hermes-mnemosyne-circle-64.png",
        cwd="~",
        auto_start=False,
    )
