---
name: notify-test
description: Fire a test claude-notify notification (sound + toast, or the animated overlay instead if enabled). Optional argument = delay in seconds before firing, so the user can minimize the terminal first. Use when the user invokes /notify-test or asks to test their notifications.
---

# Test the claude-notify notification

Fire the plugin's notification pipeline once so the user can see/hear it.

The notification script lives in this plugin at
`${CLAUDE_PLUGIN_ROOT}/hooks/notify.sh`. If that placeholder is not resolved,
locate `claude-notify-plugin/hooks/notify.sh` (or `claude-notify/hooks/notify.sh`)
under `~/.claude/plugins/`.

Steps:

1. If the user gave a delay argument N (seconds), tell them to minimize the
   terminal now, then wait N seconds first (e.g.
   `powershell.exe -NoProfile -Command "Start-Sleep -Seconds N"` on Windows,
   or include the delay before the script call).
2. Run the notification:
   ```
   bash "${CLAUDE_PLUGIN_ROOT}/hooks/notify.sh" "Test notification - it works!"
   ```
3. Tell the user what to expect: a sound, plus either a Windows toast
   (default) or — if the animated overlay is enabled (see /notify-anim) —
   an animated card with the logo bottom-right for ~4 seconds instead of
   the toast. Clicking either one focuses this terminal. On macOS/Linux,
   a native notification appears.
