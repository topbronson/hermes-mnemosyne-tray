"""Liveness probe for the Mnemosyne dashboard.

The Mnemosyne dashboard exposes a port; if it's accepting connections,
we consider it alive. The port is taken from :attr:`Config.port` so the
install script can re-target the host/port via the systemd unit's
``Environment=`` line.
"""

from __future__ import annotations

from hermes_tray import Config, LivenessProbe, PortListeningProbe

__all__ = ["make_probe"]


def make_probe(config: Config) -> LivenessProbe:
    """Return the liveness probe for the Mnemosyne dashboard."""
    return PortListeningProbe(host=config.host, port=config.port)
