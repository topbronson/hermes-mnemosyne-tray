"""Tests for the Mnemosyne-specific Config factory."""
from __future__ import annotations

from hermes_mnemosyne_tray.config import make_config


def test_config_defaults() -> None:
    cfg = make_config()
    assert cfg.name == "mnemosyne"
    assert cfg.title == "Mnemosyne"
    assert cfg.bin == "hermes"
    # The Mnemosyne plugin is served by the unified `hermes dashboard` —
    # we supervise that, not a separate `mnemosyne dashboard` command.
    assert cfg.subcommand == ("dashboard",)
    # Same port as the unified hermes-dashboard.
    assert cfg.port == 9119
    # We don't auto-start; the parent dashboard owns that.
    assert cfg.auto_start is False


def test_config_icon_fallback() -> None:
    cfg = make_config()
    assert cfg.icon_fallback == "hermes-mnemosyne-circle-64.png"
    # icon_fallback_path should be a Path inside the icon_dir
    assert str(cfg.icon_fallback_path).endswith("hermes-mnemosyne-circle-64.png")


def test_config_targets_unified_dashboard_url() -> None:
    cfg = make_config()
    # The "Open Mnemosyne" menu item opens the unified dashboard, not
    # a separate Mnemosyne port (the Mnemosyne plugin is integrated there).
    assert "9119" in cfg.url
