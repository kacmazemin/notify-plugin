---
name: notify-mute
description: Mute or unmute all claude-notify notifications (sound, toast, and overlay), or check mute status. Use when the user invokes /notify-mute or asks to silence, mute, disable, or re-enable Claude notifications temporarily.
---

# Mute / unmute claude-notify

Toggle all notifications on/off. A `mute` flag in the state dir makes
`notify.sh` skip everything (sound + overlay). Reply one line.

```
d="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"; mkdir -p "$d"
touch "$d/mute"        # on  — silence all
rm -f "$d/mute"        # off — restore
[ -f "$d/mute" ] && echo "notifications: MUTED" || echo "notifications: ON (default)"   # status
```

Takes effect on the next notification. Muting also silences `/notify-test`.
