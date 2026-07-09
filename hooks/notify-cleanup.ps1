# claude-notify: remove all per-user artifacts this plugin creates on Windows.
# Safe to run anytime; removes only claude-notify's own files/registry key.
# Leaves the plugin install itself alone - run /plugin uninstall for that.
$ErrorActionPreference = 'SilentlyContinue'
$removed = @()

# 1. HKCU protocol handler registered by notify-done.ps1 (claude-notify:focus)
$protoKey = 'HKCU:\Software\Classes\claude-notify'
if (Test-Path $protoKey) {
    Remove-Item -Path $protoKey -Recurse -Force
    if (-not (Test-Path $protoKey)) { $removed += 'registry: HKCU\Software\Classes\claude-notify' }
}

# 2. State dir: focus-target.txt, focus-launch.vbs, mute, duration, logo.png
$stateDir = Join-Path $env:LOCALAPPDATA 'claude-done-notify'
if (Test-Path $stateDir) {
    Remove-Item -Path $stateDir -Recurse -Force
    if (-not (Test-Path $stateDir)) { $removed += "files: $stateDir" }
}

if ($removed.Count -eq 0) {
    Write-Output 'claude-notify: nothing to clean (no artifacts found).'
} else {
    Write-Output 'claude-notify: removed ->'
    $removed | ForEach-Object { Write-Output "  $_" }
}
