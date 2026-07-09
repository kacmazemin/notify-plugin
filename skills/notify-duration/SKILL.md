---
name: notify-duration
description: Set how long the claude-notify overlay card stays on screen before fading (Windows overlay, default 5s), or check the current value. Use when the user invokes /notify-duration or asks to make the notification stay longer/shorter, change how long the popup/card/overlay lasts, or reset the duration.
---

# Set claude-notify overlay duration

How long the overlay card stays fully visible before fading (Windows overlay
only, default 5s, clamped 0.5–60). Stored in the `duration` state file. Reply one
line.

State dir: `${LOCALAPPDATA:-$HOME/.config}/claude-done-notify`. Map the request to
a line and run it (bash, all platforms):

```
d="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"; mkdir -p "$d"
printf 10 > "$d/duration"       # keep the card up 10s (arg = seconds, 0.5–60)
rm -f "$d/duration"             # reset to the 5s default
```

Status (no arg):
```
d="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"
[ -f "$d/duration" ] && echo "duration: $(cat "$d/duration")s" || echo "duration: 5s (default)"
```

Takes effect on the next notification. Windows-only — the overlay is the only
visual that honors it.
