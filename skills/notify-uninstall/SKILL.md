---
name: notify-uninstall
description: Remove all per-user artifacts claude-notify creates (the HKCU claude-notify: protocol handler, the focus-launch.vbs shim, focus-target.txt, and the mute/anim-off/logo state files). Use when the user invokes /notify-uninstall or asks to fully clean up, purge, or remove claude-notify's leftover files and registry entries. Does not uninstall the plugin itself.
---

# Clean up claude-notify artifacts

The plugin writes per-user state that is NOT removed when the plugin is
uninstalled through `/plugin`. This clears it:

- **Windows:** the `HKCU\Software\Classes\claude-notify` protocol key (registered
  by `hooks/notify-done.ps1` for the toast/overlay click) and the state dir
  `%LOCALAPPDATA%\claude-done-notify\` (holds `focus-target.txt`,
  `focus-launch.vbs`, `mute`, `anim-off`, `logo.png`).
- **macOS/Linux:** only the state dir `~/.config/claude-done-notify/` (holds
  `mute`). No registry involved.

## Steps

1. Run the cleanup.

   **Windows** — run the bundled script (removes registry key + state dir and
   reports what it removed):
   ```
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/hooks/notify-cleanup.ps1"
   ```
   If `${CLAUDE_PLUGIN_ROOT}` is not resolved, locate `notify-cleanup.ps1`
   under `~/.claude/plugins/` (in `claude-notify/hooks/` or
   `claude-notify-plugin/hooks/`).

   **macOS/Linux** — remove the state dir:
   ```
   bash -c 'rm -rf "$HOME/.config/claude-done-notify" && echo "claude-notify: removed ~/.config/claude-done-notify"'
   ```

2. Report what was removed (the script prints it; on unix confirm the echo).

3. Remind the user this only clears leftover artifacts — the plugin is still
   installed. To remove the plugin itself:
   `/plugin uninstall claude-notify@claude-notify-marketplace`, or use the
   `/plugin` menu. Best order: run `/notify-uninstall` first (while the script
   is still available), then uninstall the plugin.
