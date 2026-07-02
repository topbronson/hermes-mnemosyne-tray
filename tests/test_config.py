"""Tests for the Mnemosyne-specific Config factory."""
from __future__ import annotations

from hermes_mnemosyne_tray.config import make_config


def test_config_defaults() -> None:
    cfg = make_config()
    assert cfg.name == "mnemosyne"
    assert cfg.title == "Mnemosyne"
    # The Mnemosyne dashboard is a standalone server (the
    # mnemosyne-dashboard plugin's server.py) — not part of `hermes dashboard`.
    assert cfg.bin == "python3"
    assert cfg.subcommand[0].endswith("server.py")
    assert cfg.port == 8765
    assert cfg.host == "localhost"


def test_config_icon_fallback() -> None:
    cfg = make_config()
    assert cfg.icon_fallback == "hermes-mnemosyne-circle-64.png"
    # icon_fallback_path should be a Path inside the icon_dir
    assert str(cfg.icon_fallback_path).endswith("hermes-mnemosyne-circle-64.png")


def test_config_targets_mnemosyne_port() -> None:
    cfg = make_config()
    # The "Open Mnemosyne" menu item opens port 8765 (the plugin's
    # standalone server), not the unified hermes-dashboard's 9119.
    assert "8765" in cfg.url


def test_config_includes_db_flag() -> None:
    """server.py needs the --db flag to find the SQLite database."""
    cfg = make_config()
    assert "--db" in cfg.subcommand
    assert any("mnemosyne.db" in arg for arg in cfg.subcommand)
