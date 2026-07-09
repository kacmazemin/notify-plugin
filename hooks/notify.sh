#!/usr/bin/env bash
# Cross-platform Claude Code notification.
# Windows -> PowerShell toast/overlay + sound, macOS -> osascript, Linux -> notify-send.
# Usage: notify.sh [message]

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TITLE="Claude Code"
MSG="${1:-Job done - Claude has finished working.}"

STATE_DIR="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"

# Resolve the effective visibility mode: silent | sound | toast | overlay.
# Priority: explicit 'mode' file (set by /notify-visibility), else legacy flags
# (mute -> silent, anim-off -> toast) so /notify-mute and /notify-anim still work,
# else the default 'overlay'.
MODE=""
if [ -f "$STATE_DIR/mode" ]; then
    MODE="$(tr -d '[:space:]' < "$STATE_DIR/mode" | tr '[:upper:]' '[:lower:]')"
fi
if [ -z "$MODE" ]; then
    if   [ -f "$STATE_DIR/mute" ];     then MODE="silent"
    elif [ -f "$STATE_DIR/anim-off" ]; then MODE="toast"
    else MODE="overlay"; fi
fi
case "$MODE" in silent|sound|toast|overlay) ;; *) MODE="overlay";; esac

# Nothing to do when silent.
[ "$MODE" = "silent" ] && exit 0

if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$DIR/notify-done.ps1" -Message "$MSG" -Mode "$MODE" >/dev/null 2>&1
elif command -v osascript >/dev/null 2>&1; then
    # macOS has no overlay: overlay/toast both show a native notification (with
    # sound); 'sound' plays the alert only.
    if [ "$MODE" = "sound" ]; then
        osascript -e 'beep' >/dev/null 2>&1
    else
        osascript -e "display notification \"$MSG\" with title \"$TITLE\" sound name \"Glass\"" >/dev/null 2>&1
    fi
elif command -v notify-send >/dev/null 2>&1; then
    # Linux: overlay/toast/sound all surface as a native notification (no
    # reliable sound-only path); only 'silent' suppresses it (handled above).
    notify-send "$TITLE" "$MSG" >/dev/null 2>&1
fi
exit 0
