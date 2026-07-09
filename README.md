# claude-notify

> Desktop notification + sound whenever Claude Code finishes a job or is waiting for your input — so you can tab away while it works.

[![Version](https://img.shields.io/badge/version-1.3.1-blue.svg)](.claude-plugin/plugin.json)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)](#platform-support)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## Features

- **Cross-platform** — native notifications on Windows, macOS, and Linux
- **Click-to-focus (Windows)** — clicking the toast or overlay brings the terminal Claude is running in back to the foreground, even if minimized. Works with Windows Terminal, VS Code, PowerShell, and cmd — including when Claude was launched straight from Explorer (shortcut / Win+R / double-click)
- **Animated overlay (Windows)** — animated card with your logo (gentle pulse) in the bottom-right corner instead of the plain toast
- **Visibility modes** — one dial (`/notify-visibility`) picks how much you get: `overlay`, `toast`, `sound` (audio only), or `silent`
- **Configurable overlay duration** — how long the card stays on screen (default 5s)
- **Zero admin rights** — user-level registry key only
- **Clean uninstall** — `/notify-uninstall` removes every per-user artifact the plugin creates

## Platform Support

| Platform | Notification | Sound |
|----------|--------------|-------|
| Windows  | Native toast + animated overlay | System sound |
| macOS    | `osascript` | Glass sound |
| Linux    | `notify-send` | — |

The overlay, visibility modes, and duration control are Windows-only. On macOS/Linux the plugin fires the native notification, and `silent` suppresses it.

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
| `/notify-visibility <mode>` | Set the notification mode: `overlay`, `toast`, `sound`, `silent`, or `duration <sec>`. Supersedes `/notify-mute` and `/notify-anim` |
| `/notify-anim on\|off\|status` | Toggle the animated overlay (Windows) — legacy, still works |
| `/notify-mute on\|off\|status` | Temporarily silence all notifications — legacy, still works |
| `/notify-uninstall` | Remove all per-user artifacts (registry key + state files) |

## Visibility Modes

`/notify-visibility` is the single dial for how notifications appear:

| Mode | Sound | Visual |
|------|-------|--------|
| `overlay` | ✓ | animated card (default) |
| `toast` | ✓ | Windows toast |
| `sound` | ✓ | none |
| `silent` | ✗ | none |

```
/notify-visibility toast     # switch to the plain toast
/notify-visibility sound     # sound only, no popup
/notify-visibility silent    # nothing at all
/notify-visibility overlay   # back to the animated card (default)
/notify-visibility           # report the current mode + duration
```

The mode is stored in `%LOCALAPPDATA%\claude-done-notify\mode` (macOS/Linux: `~/.config/claude-done-notify/mode`). It supersedes the legacy `/notify-mute` and `/notify-anim` flags, which are still honored as a fallback when no mode is set — so existing setups keep working.

### Overlay Duration

How long the card stays fully visible before fading out (Windows overlay only, default 5 seconds):

```
/notify-visibility duration 10     # keep it up for 10 seconds (0.5–60)
/notify-visibility duration reset  # back to the 5s default
```

Stored in `%LOCALAPPDATA%\claude-done-notify\duration`.

## Animated Overlay (Windows)

On by default (the `overlay` mode). Shows an animated card with the bundled robot animation in the bottom-right corner instead of the toast. Clicking the card focuses the terminal, same as a toast click.

### Custom Logo

The overlay visual is resolved in this order:

1. `%LOCALAPPDATA%\claude-done-notify\logo.png` — per-user override; drop any PNG here to use your own (transparent background looks best), shown with a gentle pulse
2. `assets/logo.png` bundled with the plugin (not shipped by default)
3. `assets/robot_knock_retro.gif` — bundled animated GIF, the default
4. None found — falls back to a spinning 3D cube

## How It Works

The plugin registers `Stop` and `Notification` hooks (`hooks/hooks.json`) that run `hooks/notify.sh` asynchronously. The script resolves the visibility mode, detects your OS, and fires the matching notification. On Windows it delegates to `hooks/notify-done.ps1` (toast) and `hooks/notify-anim.ps1` (overlay).

**Windows click-to-focus:** the toast/overlay uses protocol activation. On first run the script registers a user-level `claude-notify:` URI protocol under `HKCU\Software\Classes` (no admin rights) pointing at `hooks/focus-terminal.ps1`, and remembers which terminal window Claude was running in. Clicking the notification restores and focuses that window. The window is located by walking Claude's process ancestry — skipping shell/desktop processes like `explorer.exe` so the real console is found even when Claude was launched from Explorer.

## Uninstall

Remove the plugin:

```
/plugin uninstall claude-notify@claude-notify-marketplace
```

The plugin also writes per-user state (registry protocol key, focus shim, mode/duration files) that a plugin uninstall does **not** clean up. Clear it first with:

```
/notify-uninstall
```

Or manually on Windows:

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
│   ├── notify.sh            # OS-detection + mode-resolution entrypoint
│   ├── notify-done.ps1      # Windows toast + sound, mode-aware
│   ├── notify-anim.ps1      # animated overlay renderer (configurable duration)
│   ├── notify-cleanup.ps1   # removes registry key + state files
│   └── focus-terminal.ps1   # protocol handler for click-to-focus
├── skills/
│   ├── notify-test/         # /notify-test command
│   ├── notify-visibility/   # /notify-visibility command
│   ├── notify-anim/         # /notify-anim command (legacy)
│   ├── notify-mute/         # /notify-mute command (legacy)
│   └── notify-uninstall/    # /notify-uninstall command
├── assets/                  # bundled logo
└── README.md
```

## Contributing

Issues and PRs welcome. Please include your OS and terminal when reporting bugs.

## License

MIT — see [LICENSE](LICENSE).

## Author

**Mehmet Kacmaz** — [kacmazemin72@gmail.com](mailto:kacmazemin72@gmail.com)
