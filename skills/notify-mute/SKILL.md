---
name: notify-mute
description: Mute or unmute all claude-notify notifications (sound, toast, and overlay), or check mute status. Use when the user invokes /notify-mute or asks to silence, mute, disable, or re-enable Claude notifications temporarily.
---

# Mute / unmute claude-notify

All notifications (sound, toast, overlay, on every platform) are silenced by
a flag file, checked by `hooks/notify.sh` before firing anything:

- Windows: `%LOCALAPPDATA%\claude-done-notify\mute`
- macOS/Linux: `~/.config/claude-done-notify/mute`

Interpret the user's argument and act (bash works on all platforms):

- **on** (or "mute", "silence"): create the flag file:
  ```
  bash -c 'd="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"; mkdir -p "$d" && touch "$d/mute"'
  ```
- **off** (or "unmute"): remove the flag file:
  ```
  bash -c 'rm -f "${LOCALAPPDATA:-$HOME/.config}/claude-done-notify/mute"'
  ```
- **status** or no argument: check and report:
  ```
  bash -c 'if [ -f "${LOCALAPPDATA:-$HOME/.config}/claude-done-notify/mute" ]; then echo "notifications: MUTED"; else echo "notifications: ON (default)"; fi'
  ```

Notes:
- The change takes effect on the very next notification — no restart needed.
- Muting also silences `/notify-test`; mention that if the user tests while
  muted and wonders why nothing happened.
- This is a temporary per-user mute. To remove the plugin entirely, use
  `/plugin uninstall claude-notify@claude-notify-marketplace`, or disable it via the
  `/plugin` menu.
