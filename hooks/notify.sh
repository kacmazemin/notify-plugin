#!/usr/bin/env bash
# Cross-platform Claude Code notification.
# Windows -> PowerShell toast/overlay + sound, macOS -> osascript, Linux -> notify-send.
# Usage: notify.sh [message]

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TITLE="Claude Code"
MSG="${1:-Job done - Claude has finished working.}"

STATE_DIR="${LOCALAPPDATA:-$HOME/.config}/claude-done-notify"

# Muted? A 'mute' flag (toggled by /notify-mute) silences everything. Otherwise
# the notification fires: animated overlay + sound on Windows, native
# notification elsewhere.
[ -f "$STATE_DIR/mute" ] && exit 0

if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$DIR/notify-done.ps1" -Message "$MSG" >/dev/null 2>&1
elif command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$MSG\" with title \"$TITLE\" sound name \"Glass\"" >/dev/null 2>&1
elif command -v notify-send >/dev/null 2>&1; then
    notify-send "$TITLE" "$MSG" >/dev/null 2>&1
fi
exit 0
