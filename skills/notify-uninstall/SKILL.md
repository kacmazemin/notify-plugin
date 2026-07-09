---
name: notify-uninstall
description: Remove all per-user artifacts claude-notify creates (the HKCU claude-notify: protocol handler, the focus-launch.vbs shim, focus-target.txt, and the mute/anim-off/logo state files). Use when the user invokes /notify-uninstall or asks to fully clean up, purge, or remove claude-notify's leftover files and registry entries. Does not uninstall the plugin itself.
---

# Clean up claude-notify artifacts

The plugin writes per-user state that is NOT removed when the plugin is
uninstalled through `/plugin`. This clears it:

> **Important — do this while the plugin is still active and it only clears
> temporarily.** The `Stop`/`Notification` hooks recreate `focus-launch.vbs`
> and `focus-target.txt` (and re-register the protocol key) on the very next
> notification — i.e. the next time Claude finishes a turn. To make removal
> permanent, uninstall the plugin FIRST (which stops the hooks), THEN clean up.
> See the order in step 3.

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
   If the plugin is still installed, warn the user the focus files will be
   recreated on the next notification — that is expected, not a failure.

3. Explain the correct order for **permanent** removal, since a live hook
   rebuilds the artifacts:

   1. Uninstall the plugin first, to stop the hooks:
      `/plugin uninstall claude-notify@claude-notify-marketplace` (or the
      `/plugin` menu).
   2. Then remove the leftovers. The bundled script is gone with the plugin, so
      use the raw removal:
      - **Windows:**
        ```
        powershell -NoProfile -Command "Remove-Item -Recurse -Force 'HKCU:\Software\Classes\claude-notify','$env:LOCALAPPDATA\claude-done-notify' -EA SilentlyContinue"
        ```
      - **macOS/Linux:**
        ```
        rm -rf "$HOME/.config/claude-done-notify"
        ```

   Alternatively, to keep the plugin installed but stop it recreating anything,
   set `/notify-visibility silent` — silent mode exits before `notify-done.ps1`
   runs, so nothing gets re-registered.
