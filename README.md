# claude-notify

> Desktop notification + sound whenever Claude Code finishes a job or is waiting for your input — so you can tab away while it works.

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](.claude-plugin/plugin.json)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)](#platform-support)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## Features

- **Cross-platform** — native notifications on Windows, macOS, and Linux
- **Click-to-focus (Windows)** — clicking the toast brings the terminal Claude is running in back to the foreground, even if minimized. Works with Windows Terminal, VS Code, PowerShell, and cmd
- **Animated overlay (Windows)** — optional animated card with your logo (gentle pulse) in the bottom-right corner instead of the plain toast
- **Zero admin rights** — user-level registry key only
- **Mute toggle** — silence temporarily without uninstalling

## Platform Support

| Platform | Notification | Sound |
|----------|--------------|-------|
| Windows  | Native toast + animated overlay | System sound |
| macOS    | `osascript` | Glass sound |
| Linux    | `notify-send` | — |

## Install

```
/plugin marketplace add kacmazemin/notify-plugin
/plugin install claude-notify@claude-notify-marketplace
```

Or install from a local clone:

```
git clone https://github.com/kacmazemin/notify-plugin
/plugin marketplace add ./notify-plugin
/plugin install claude-notify@claude-notify-marketplace
```

## Commands

| Command | Description |
|---------|-------------|
| `/notify-test [seconds]` | Fire a test notification (optional delay so you can minimize the terminal first) |
| `/notify-anim on\|off\|status` | Toggle the animated overlay (Windows) |
| `/notify-mute on\|off\|status` | Temporarily silence all notifications (flag file, cross-platform) |

## Animated Overlay (Windows)

On by default. Shows an animated card with the bundled robot animation in the bottom-right corner instead of the toast. Clicking the card focuses the terminal, same as a toast click.

Disable:

```
/notify-anim off
```

Creates the flag file `%LOCALAPPDATA%\claude-done-notify\anim-off` and falls back to the plain toast. Re-enable with `/notify-anim on`.

### Custom Logo

The overlay visual is resolved in this order:

1. `%LOCALAPPDATA%\claude-done-notify\logo.png` — per-user override; drop any PNG here to use your own (transparent background looks best), shown with a gentle pulse
2. `assets/logo.png` bundled with the plugin (not shipped by default)
3. `assets/robot_knock_retro.gif` — bundled animated GIF, the default
4. None found — falls back to a spinning 3D cube

## How It Works

The plugin registers `Stop` and `Notification` hooks (`hooks/hooks.json`) that run `hooks/notify.sh` asynchronously. The script detects your OS and fires the matching native notification. On Windows it delegates to `hooks/notify-done.ps1` for the toast.

**Windows click-to-focus:** the toast uses protocol activation. On first run the script registers a user-level `claude-notify:` URI protocol under `HKCU\Software\Classes` (no admin rights) pointing at `hooks/focus-terminal.ps1`, and remembers which terminal window Claude was running in. Clicking the toast restores and focuses that window.

## Uninstall

```
/plugin uninstall claude-notify@claude-notify-marketplace
```

To also remove Windows registry and cache:

```powershell
Remove-Item -Recurse "HKCU:\Software\Classes\claude-notify"
Remove-Item -Recurse "$env:LOCALAPPDATA\claude-done-notify"
```

## Repository Layout

```
notify-plugin/
├── .claude-plugin/
│   ├── plugin.json          # plugin manifest
│   └── marketplace.json     # marketplace manifest
├── hooks/
│   ├── hooks.json           # Stop + Notification hook wiring
│   ├── notify.sh            # OS-detection entrypoint
│   ├── notify-done.ps1      # Windows toast + overlay
│   ├── notify-anim.ps1      # animated overlay renderer
│   └── focus-terminal.ps1   # protocol handler for click-to-focus
├── skills/
│   ├── notify-test/         # /notify-test command
│   ├── notify-anim/         # /notify-anim command
│   └── notify-mute/         # /notify-mute command
├── assets/                  # bundled logo
└── README.md
```

## Contributing

Issues and PRs welcome. Please include your OS and terminal when reporting bugs.

## License

MIT — see [LICENSE](LICENSE).

## Author

**Mehmet Kacmaz** — [kacmazemin72@gmail.com](mailto:kacmazemin72@gmail.com)
