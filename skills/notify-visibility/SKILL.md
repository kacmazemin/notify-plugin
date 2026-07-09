---
name: notify-visibility
description: Set how claude-notify notifications appear with one dial — silent, sound, toast, or overlay. Use when the user invokes /notify-visibility or asks to change the notification mode/style/visibility, make it sound-only, use the toast instead of the overlay, or check the current mode. Supersedes /notify-mute and /notify-anim.
---

# Set claude-notify visibility mode

One dial controls the whole notification. Four modes:

| mode      | sound | visual                              |
|-----------|-------|-------------------------------------|
| `overlay` | yes   | animated card (default)             |
| `toast`   | yes   | Windows toast                       |
| `sound`   | yes   | none                                |
| `silent`  | no    | none                                |

Backed by a single file `mode` in the state dir, read by `hooks/notify.sh`:

- Windows: `%LOCALAPPDATA%\claude-done-notify\mode`
- macOS/Linux: `~/.config/claude-done-notify/mode`

The file holds exactly one word: `overlay`, `toast`, `sound`, or `silent`.
No file = default `overlay` (with legacy `/notify-mute` and `/notify-anim`
flags honored as a fallback when no `mode` file exists).

## Act on the user's argument

Map the request to one of the four modes, then write it (bash works on all
platforms):

- **overlay** (or "animation", "card", "default"):
  ```
  bash -c 'd="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"; mkdir -p "$d" && printf overlay > "$d/mode"'
  ```
- **toast** (or "notification", "no animation"):
  ```
  bash -c 'd="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"; mkdir -p "$d" && printf toast > "$d/mode"'
  ```
- **sound** (or "sound only", "just a beep", "no popup"):
  ```
  bash -c 'd="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"; mkdir -p "$d" && printf sound > "$d/mode"'
  ```
- **silent** (or "off", "mute", "nothing"):
  ```
  bash -c 'd="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"; mkdir -p "$d" && printf silent > "$d/mode"'
  ```
- **duration N** (or "show longer", "keep it up N seconds") — set how long the
  overlay card stays before fading (Windows overlay only; 0.5–60s, default 5).
  Write the number to the `duration` file:
  ```
  bash -c 'd="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"; mkdir -p "$d" && printf %s "N" > "$d/duration"'
  ```
  To reset to default, delete it:
  ```
  bash -c 'rm -f "${LOCALAPPDATA:-$HOME/.config}/claude-done-notify/duration"'
  ```
- **status** or no argument — report the effective mode and overlay duration:
  ```
  bash -c 'd="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"; if [ -f "$d/mode" ]; then echo "mode: $(cat "$d/mode")"; elif [ -f "$d/mute" ]; then echo "mode: silent (legacy mute flag)"; elif [ -f "$d/anim-off" ]; then echo "mode: toast (legacy anim-off flag)"; else echo "mode: overlay (default)"; fi; if [ -f "$d/duration" ]; then echo "overlay duration: $(cat "$d/duration")s"; else echo "overlay duration: 5s (default)"; fi'
  ```

## Notes

- Takes effect on the very next notification — no restart needed.
- The `mode` file wins over the legacy `mute` / `anim-off` flags. If a user set
  those via `/notify-mute` or `/notify-anim` and now uses this skill, the `mode`
  file takes over; to fall back to the legacy flags, delete the `mode` file.
- Platform limits: `overlay` is Windows-only. On macOS, `overlay`/`toast` both
  show a native notification and `sound` plays a beep. On Linux, everything
  except `silent` shows a native notification (no reliable sound-only path).
- After setting, confirm the new mode and suggest `/notify-test` to preview it
  (note: `/notify-test` shows nothing in `silent` mode).
