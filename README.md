# claude-notify

> Desktop notification + sound whenever Claude Code finishes a job or is waiting for your input — so you can tab away while it works.

[![Version](https://img.shields.io/badge/version-1.4.0-blue.svg)](.claude-plugin/plugin.json)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)](#platform-support)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## Features

- **Cross-platform** — native notifications on Windows, macOS, and Linux
- **Click-to-focus (Windows)** — clicking the overlay brings the terminal Claude is running in back to the foreground, even if minimized. Works with Windows Terminal, VS Code, PowerShell, and cmd — including when Claude was launched straight from Explorer (shortcut / Win+R / double-click)
- **Animated overlay (Windows)** — animated card with your logo (gentle pulse) in the bottom-right corner
- **Mute toggle** — `/notify-mute` silences everything on/off, no fuss
- **Configurable overlay duration** — `/notify-duration` sets how long the card stays on screen (default 5s)
- **Zero admin rights** — user-level registry key only
- **Cache clear** — `/notify-clear-cache` wipes every per-user artifact the plugin writes (registry key + state files). Note: this does **not** remove the plugin or stop notifications — see [Uninstall](#uninstall)

## Platform Support

| Platform | Notification | Sound |
|----------|--------------|-------|
| Windows  | Animated overlay | System sound |
| macOS    | `osascript` | Glass sound |
| Linux    | `notify-send` | — |

The overlay and duration control are Windows-only. On macOS/Linux the plugin fires the native notification; `/notify-mute` suppresses it everywhere.

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
| `/notify-mute [on\|off\|status]` | Silence all notifications on/off, or check status |
| `/notify-duration <seconds\|reset>` | How long the overlay card stays on screen (Windows, default 5s) |
| `/notify-clear-cache` | Clear per-user artifacts (registry key + state files). Does **not** remove the plugin or stop the hooks — see [Uninstall](#uninstall) |

## Muting

`/notify-mute` is the on/off switch for everything (sound + overlay):

```
/notify-mute on       # silence all notifications
/notify-mute off      # restore
/notify-mute status   # report current state
/notify-mute          # same as status
```

The flag lives in `%LOCALAPPDATA%\claude-done-notify\mute` (macOS/Linux: `~/.config/claude-done-notify/mute`) and takes effect on the next notification. Muting also silences `/notify-test`.

## Overlay Duration

How long the card stays fully visible before fading out (Windows overlay only, default 5 seconds):

```
/notify-duration 10       # keep it up for 10 seconds (0.5–60)
/notify-duration reset    # back to the 5s default
/notify-duration          # report the current value
```

Stored in `%LOCALAPPDATA%\claude-done-notify\duration`.

## Animated Overlay (Windows)

On Windows the notification is an animated card with the bundled robot animation in the bottom-right corner. Clicking the card focuses the terminal.

### Custom Logo

The overlay visual is resolved in this order:

1. `%LOCALAPPDATA%\claude-done-notify\logo.png` — per-user override; drop any PNG here to use your own (transparent background looks best), shown with a gentle pulse
2. `assets/logo.png` bundled with the plugin (not shipped by default)
3. `assets/robot_knock_retro.gif` — bundled animated GIF, the default
4. None found — falls back to a spinning 3D cube

## How It Works

The plugin registers `Stop` and `Notification` hooks (`hooks/hooks.json`) that run `hooks/notify.sh` asynchronously. The script checks the `mute` flag, detects your OS, and — unless muted — fires the notification. On Windows it delegates to `hooks/notify-done.ps1`, which plays the sound and launches the animated overlay (`hooks/notify-anim.ps1`).

**Windows click-to-focus:** the overlay uses protocol activation. On first run the script registers a user-level `claude-notify:` URI protocol under `HKCU\Software\Classes` (no admin rights) pointing at `hooks/focus-terminal.ps1`, and remembers which terminal window Claude was running in. Clicking the notification restores and focuses that window. The window is located by walking Claude's process ancestry — skipping shell/desktop processes like `explorer.exe` so the real console is found even when Claude was launched from Explorer.

## Uninstall

> **`/notify-clear-cache` alone does not stop notifications.** It only clears the per-user artifacts (registry key + state files). While the plugin is still installed, the `Stop`/`Notification` hooks recreate those artifacts on the next turn, so notifications keep firing. To actually stop them you must uninstall the plugin (or `/notify-mute`). **Order matters.**

**Full removal — do these in order:**

**1. Uninstall the plugin** (this is what stops the hooks):

```
/plugin uninstall claude-notify@claude-notify-marketplace
```

**2. Clear the leftover per-user state** the plugin uninstall does **not** touch (registry protocol key, focus shim, mute/duration files).

The bundled cleanup script is gone with the plugin, so clean up manually on Windows:

```powershell
Remove-Item -Recurse -Force "HKCU:\Software\Classes\claude-notify","$env:LOCALAPPDATA\claude-done-notify" -ErrorAction SilentlyContinue
```

macOS/Linux:

```bash
rm -rf "$HOME/.config/claude-done-notify"
```

**Just want it quiet, keep the plugin?** Skip all of the above:

```
/notify-mute on
```

## Repository Layout

```
notify-plugin/
├── .claude-plugin/
│   ├── plugin.json          # plugin manifest
│   └── marketplace.json     # marketplace manifest
├── hooks/
│   ├── hooks.json           # Stop + Notification hook wiring
│   ├── notify.sh            # OS-detection + mute-check entrypoint
│   ├── notify-done.ps1      # Windows sound + click-to-focus registration
│   ├── notify-anim.ps1      # animated overlay renderer (configurable duration)
│   ├── notify-cleanup.ps1   # removes registry key + state files
│   └── focus-terminal.ps1   # protocol handler for click-to-focus
├── skills/
│   ├── notify-test/         # /notify-test command
│   ├── notify-mute/         # /notify-mute command
│   ├── notify-duration/     # /notify-duration command
│   └── notify-clear-cache/  # /notify-clear-cache command
├── assets/                  # bundled logo
└── README.md
```

## Contributing

Issues and PRs welcome. Please include your OS and terminal when reporting bugs.

## License

MIT — see [LICENSE](LICENSE).

## Author

**Mehmet Kacmaz** — [kacmazemin72@gmail.com](mailto:kacmazemin72@gmail.com)
