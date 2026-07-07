#!/usr/bin/env bash
# Cross-platform Claude Code notification.
# Windows -> PowerShell toast + sound, macOS -> osascript, Linux -> notify-send.
# Usage: notify.sh [message]

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TITLE="Claude Code"
MSG="${1:-Job done - Claude has finished working.}"

# Muted? (flag created by /notify-mute) - skip all notifications silently.
# Windows: %LOCALAPPDATA%\claude-done-notify\mute, elsewhere: ~/.config/claude-done-notify/mute
if [ -f "${LOCALAPPDATA:-$HOME/.config}/claude-done-notify/mute" ]; then
    exit 0
fi

if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$DIR/notify-done.ps1" -Message "$MSG" >/dev/null 2>&1
elif command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$MSG\" with title \"$TITLE\" sound name \"Glass\"" >/dev/null 2>&1
elif command -v notify-send >/dev/null 2>&1; then
    notify-send "$TITLE" "$MSG" >/dev/null 2>&1
fi
exit 0
