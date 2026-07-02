"""Tests for the Mnemosyne-specific Config factory."""

from __future__ import annotations

from hermes_mnemosyne_tray.config import make_config


def test_config_defaults() -> None:
    cfg = make_config()
    assert cfg.name == "mnemosyne"
    assert cfg.title == "Mnemosyne"
    assert cfg.bin == "hermes"
    assert cfg.subcommand == ("mnemosyne", "dashboard", "start")
    assert cfg.port == 8765


def test_config_icon_fallback() -> None:
    cfg = make_config()
    assert cfg.icon_fallback == "hermes-mnemosyne-circle-64.png"
    # icon_fallback_path should be a Path inside the icon_dir
    assert str(cfg.icon_fallback_path).endswith("hermes-mnemosyne-circle-64.png")
