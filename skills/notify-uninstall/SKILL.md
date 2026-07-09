---
name: notify-uninstall
description: Remove all per-user artifacts claude-notify creates (the HKCU claude-notify: protocol handler, the focus-launch.vbs shim, focus-target.txt, and the mode/mute/anim-off/logo state files). Use when the user invokes /notify-uninstall or asks to fully clean up, purge, or remove claude-notify's leftover files and registry entries. Does not uninstall the plugin itself.
---

# Clean up claude-notify artifacts

Removes the `HKCU\Software\Classes\claude-notify` protocol key and the state dir
(`%LOCALAPPDATA%\claude-done-notify\` / `~/.config/claude-done-notify/`). A plugin
uninstall does NOT remove these.

**While the plugin is installed this only clears temporarily** — the
Stop/Notification hook recreates the focus files + key on the next turn. For
permanent removal, uninstall the plugin FIRST, then clean up (step 3).

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

Alternative (keep plugin, stop recreation): `/notify-visibility silent` — silent
mode exits before `notify-done.ps1` runs, so nothing gets re-registered.
