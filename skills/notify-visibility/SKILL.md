---
name: notify-visibility
description: Set how claude-notify notifications appear with one dial — silent, sound, toast, or overlay (plus overlay duration). Use when the user invokes /notify-visibility or asks to change the notification mode/style/visibility, make it sound-only, use the toast instead of the overlay, set how long the overlay stays, or check the current mode. Supersedes /notify-mute and /notify-anim.
---

# Set claude-notify visibility

Modes (written to the `mode` file): `overlay` (sound + card, default), `toast`
(sound + toast), `sound` (audio only), `silent` (nothing). Reply one line.

State dir: `${LOCALAPPDATA:-$HOME/.config}/claude-done-notify`. Map the request
to a mode/action and run the matching line (bash, all platforms):

```
d="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"; mkdir -p "$d"
printf overlay > "$d/mode"      # overlay | toast | sound | silent — set mode
printf 10 > "$d/duration"       # overlay seconds (0.5–60, default 5)
rm -f "$d/mode"                 # reset mode to default overlay
rm -f "$d/duration"             # reset duration to default 5s
```

Status (no arg): read and report mode + duration:
```
d="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"
[ -f "$d/mode" ] && echo "mode: $(cat "$d/mode")" || { [ -f "$d/mute" ] && echo "mode: silent (legacy)"; } || { [ -f "$d/anim-off" ] && echo "mode: toast (legacy)"; } || echo "mode: overlay (default)"
[ -f "$d/duration" ] && echo "duration: $(cat "$d/duration")s" || echo "duration: 5s (default)"
```

Notes: takes effect next notification. `mode` file wins over legacy
`mute`/`anim-off`. Overlay + duration are Windows-only; on macOS `sound`=beep,
else native notification; Linux shows native notification unless `silent`.
