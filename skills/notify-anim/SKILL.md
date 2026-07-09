---
name: notify-anim
description: Turn the claude-notify animated overlay on or off, or check its status (Windows only). Use when the user invokes /notify-anim or asks to enable/disable the notification animation, "the logo", or "the cube".
---

# Toggle the animated overlay (Windows)

Legacy toggle (prefer `/notify-visibility`). Overlay ON = default; OFF falls
back to the plain toast, via the flag `%LOCALAPPDATA%\claude-done-notify\anim-off`.
Note: a `mode` file set by `/notify-visibility` overrides this flag. Reply one line.

```
d="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"; mkdir -p "$d"
rm -f "$d/anim-off"        # on  — remove flag (overlay)
touch "$d/anim-off"        # off — plain toast
[ -f "$d/anim-off" ] && echo "animation: OFF" || echo "animation: ON (default)"   # status
```

Custom overlay image: drop a PNG at `%LOCALAPPDATA%\claude-done-notify\logo.png`
(else bundled GIF, else spinning cube). Takes effect on the next notification.
