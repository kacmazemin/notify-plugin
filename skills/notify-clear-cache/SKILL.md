---
name: notify-clear-cache
description: Clear the per-user state claude-notify writes on your machine — the HKCU claude-notify: protocol handler, the focus-launch.vbs shim, focus-target.txt, and the mute/duration/logo state files. Use when the user invokes /notify-clear-cache or asks to clear, reset, purge, or clean up claude-notify's leftover files and registry entries. Does NOT uninstall the plugin or stop notifications.
---

# Clear claude-notify cache / state

Removes the `HKCU\Software\Classes\claude-notify` protocol key and the state dir
(`%LOCALAPPDATA%\claude-done-notify\` / `~/.config/claude-done-notify/`) — which
holds the mute flag, duration, custom logo, focus shim, and focus target. A
plugin uninstall does NOT remove these.

**This does not stop notifications.** While the plugin is installed, the
Stop/Notification hook recreates the focus files + key on the next turn. To
actually stop notifications, uninstall the plugin (see below) or `/notify-mute`.

## Run

- **Windows** (bundled script, reports what it removed):
  ```
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/hooks/notify-cleanup.ps1"
  ```
  If `${CLAUDE_PLUGIN_ROOT}` is unresolved, find `notify-cleanup.ps1` under `~/.claude/plugins/`.
- **macOS/Linux:**
  ```
  rm -rf "$HOME/.config/claude-done-notify" && echo "removed ~/.config/claude-done-notify"
  ```

Report what was removed. If the plugin is still installed, note the focus files
will reappear on the next notification — expected, not a failure.

## Permanent removal (correct order)

1. `/plugin uninstall claude-notify@claude-notify-marketplace` (stops the hooks).
2. Remove leftovers (bundled script is gone with the plugin):
   - Windows: `powershell -NoProfile -Command "Remove-Item -Recurse -Force 'HKCU:\Software\Classes\claude-notify','$env:LOCALAPPDATA\claude-done-notify' -EA SilentlyContinue"`
   - macOS/Linux: `rm -rf "$HOME/.config/claude-done-notify"`

Just want it quiet but keep the plugin? `/notify-mute`.
