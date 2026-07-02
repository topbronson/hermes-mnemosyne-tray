# hermes-mnemosyne-tray

> Tray indicator for the [Mnemosyne](https://github.com/nousresearch/hermes-agent)
> memory dashboard, auto-starting with the Hermes gateway.

A small Python tray icon for Ubuntu/GNOME that owns the lifecycle of
`hermes mnemosyne dashboard start`. Right-click the tray icon for
Start / Stop / Restart / Open / Quit. The icon is a circular crop of the
Roman wall mosaic of Mnemosyne from Tarragona (CC0).

## Features

- **State-aware icon.** Tray dot color reflects live state (🟢 running,
  🟡 starting/restarting, ⚪ stopped, 🔴 error).
- **Lifecycle actions.** Right-click menu: Start, Stop, Restart, Open in
  browser, Quit.
- **Auto-start at login.** Installs a systemd user service that starts
  alongside the Hermes gateway (`Wants=hermes-gateway.service`).
- **Env-driven config.** No source edits to retarget host/port/cwd.
- **Clean separation.** Built on
  [`hermes-tray-lib`](https://github.com/topbronson/hermes-tray-lib) —
  this repo is just a thin wrapper.

## Install

```bash
sudo apt install -y python3-gi gir1.2-gtk-3.0 gir1.2-appindicator3-0.1

git clone https://github.com/topbronson/hermes-mnemosyne-tray
cd hermes-mnemosyne-tray
./install.sh
```

By default, this installs to `~/.local`. Use `PREFIX=/usr/local ./install.sh`
for a system-wide install.

After install, enable the systemd service:

```bash
systemctl --user daemon-reload
systemctl --user enable --now hermes-mnemosyne-indicator.service
```

Check status with:

```bash
systemctl --user status hermes-mnemosyne-indicator.service
journalctl --user -u hermes-mnemosyne-indicator -f   # live logs
```

## Configuration

All configuration is via environment variables. Override at the shell
level or by editing the systemd unit's `Environment=` line.

| Variable | Default | Description |
|---|---|---|
| `HERMES_MNEMOSYNE_BIN` | `hermes` | Path to the `hermes` CLI binary |
| `HERMES_MNEMOSYNE_HOST` | `localhost` | Bind host (auto-detected from `~/.hermes/config.yaml` at install time) |
| `HERMES_MNEMOSYNE_PORT` | `8765` | Bind port |
| `HERMES_MNEMOSYNE_URL` | `http://${HOST}:${PORT}` | URL opened by "Open Mnemosyne" |
| `HERMES_MNEMOSYNE_CWD` | `~` | Working directory of the dashboard subprocess |
| `HERMES_MNEMOSYNE_RESTART_DELAY` | `5` | Seconds to wait between stop and start on restart |
| `HERMES_MNEMOSYNE_AUTO_START` | `1` | If `0`, indicator runs without launching the dashboard |
| `HERMES_MNEMOSYNE_BROWSER_CMD` | `xdg-open` | Browser launcher for the Open menu item |

## Icons

The repo does NOT ship the `.png` icons because they're derived from a
freely-licensed source image. Regenerate them after install:

```bash
# 1. Download the Mnemosyne mosaic from Wikimedia Commons (CC0)
./scripts/fetch-source.sh

# 2. Generate circular icons from the source
python3 scripts/make-circle-icon.py

# 3. Generate per-state icons with colored status dots
python3 scripts/make-status-icons.py
```

All three scripts honor `HERMES_MNEMOSYNE_LOGO_SOURCE=/path/to/your/logo.png`.

Outputs land in `~/.local/share/icons/hicolor/256x256/apps/` by default.

## License

MIT — see [LICENSE](LICENSE). Icon source is CC0 (public domain) — see
[share/icons/source/ATTRIBUTION.md](share/icons/source/ATTRIBUTION.md).

## Related

- [hermes-tray-lib](https://github.com/topbronson/hermes-tray-lib) — shared
  indicator infrastructure
- [hermes-dashboard-tray](https://github.com/topbronson/hermes-dashboard-tray) —
  sister tray for the Hermes dashboard
- [hermes-router-tray](https://github.com/topbronson/hermes-router-tray) —
  sister tray for the Hermes router
- [hermes-agent](https://github.com/nousresearch/hermes-agent) — the
  upstream agent this indicator supervises
