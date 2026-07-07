---
name: notify-anim
description: Turn the claude-notify animated overlay on or off, or check its status (Windows only). Use when the user invokes /notify-anim or asks to enable/disable the notification animation, "the logo", or "the cube".
---

# Toggle the claude-notify animated overlay

The animated overlay is ON by default and **replaces** the Windows toast
(clicking the card focuses the terminal). It is controlled by a flag file:
`%LOCALAPPDATA%\claude-done-notify\anim-off` — if it exists, the animation is
suppressed and only the toast shows.

Interpret the user's argument and act:

- **on** (or "enable"): remove the disable flag:
  ```
  powershell.exe -NoProfile -Command "Remove-Item -Path \"$env:LOCALAPPDATA\claude-done-notify\anim-off\" -Force -ErrorAction SilentlyContinue"
  ```
- **off** (or "disable"): create the disable flag:
  ```
  powershell.exe -NoProfile -Command "New-Item -Path \"$env:LOCALAPPDATA\claude-done-notify\anim-off\" -ItemType File -Force | Out-Null"
  ```
- **status** or no argument: check and report:
  ```
  powershell.exe -NoProfile -Command "if (Test-Path \"$env:LOCALAPPDATA\claude-done-notify\anim-off\") { 'animation: OFF' } else { 'animation: ON (default)' }"
  ```

The overlay's visual is resolved as `%LOCALAPPDATA%\claude-done-notify\logo.png`
(per-user PNG override, gentle pulse) first, else the plugin-bundled
`assets/logo.png`, else the bundled animated GIF `assets/robot_knock_retro.gif`
(the default), else a spinning 3D cube. To use a custom logo, drop a PNG at the
override path.

Notes:
- This is a Windows-only feature; on macOS/Linux tell the user the overlay is
  not available there.
- The change takes effect on the very next notification — no restart needed.
- After toggling, confirm the new state and suggest `/notify-test` to see it.
