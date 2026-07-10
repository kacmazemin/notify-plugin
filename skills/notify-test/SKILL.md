---
name: notify-test
description: Fire a test claude-notify notification (sound + toast/overlay). Optional argument = delay in seconds before firing, so the user can minimize the terminal first. Use when the user invokes /notify-test or asks to test their notifications.
---

# Test claude-notify

Run the notification once. Keep the response to one line — this is a cheap
action, don't over-explain.

```
CLAUDE_NOTIFY_FORCE=1 bash "${CLAUDE_PLUGIN_ROOT}/hooks/notify.sh" "Test notification - it works!"
```

`CLAUDE_NOTIFY_FORCE=1` bypasses the desktop-app skip guard so a manual test
still fires inside the Claude desktop app (where the automatic hooks stay
silent because the app has its own native notifications).

- If an argument N is given, sleep N seconds first so the user can minimize:
  `powershell.exe -NoProfile -Command "Start-Sleep N"` then run the line above.
- If `${CLAUDE_PLUGIN_ROOT}` is unresolved, find `notify.sh` under
  `~/.claude/plugins/` (`claude-notify/hooks/`).

Tip to mention once: running it in-chat costs a model turn. To test with zero
tokens, run the `bash …/notify.sh` line directly in a terminal, or in this
session prefix it with `!`.
