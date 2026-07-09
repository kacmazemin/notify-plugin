# Claude Code hook: Windows toast + sound. Clicking the toast focuses the terminal.
param(
    [string]$Message = 'Job done - Claude has finished working.',
    [string]$Mode = 'overlay'
)
$ErrorActionPreference = 'SilentlyContinue'

# Notification mode (set by /notify-visibility): silent | sound | toast | overlay.
# Default overlay. 'silent' is normally filtered upstream by notify.sh; guard here too.
$Mode = ($Mode).Trim().ToLower()
if ($Mode -notin @('silent', 'sound', 'toast', 'overlay')) { $Mode = 'overlay' }
if ($Mode -eq 'silent') { return }

# Play a notification sound (every non-silent mode).
[System.Media.SystemSounds]::Exclamation.Play()

# 'sound' = audio only, no visual - nothing to register or draw.
if ($Mode -eq 'sound') { return }

# Animated overlay (bottom-right, ~4s, click to focus terminal) for 'overlay'
# mode; 'toast' mode shows the Windows toast instead. Overlay runs detached.
$anim = Join-Path $PSScriptRoot 'notify-anim.ps1'
$animEnabled = ($Mode -eq 'overlay')
if ($animEnabled -and (Test-Path $anim)) {
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
        '-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$anim`"", '-Message', "`"$Message`""
    )
}

$stateDir = Join-Path $env:LOCALAPPDATA 'claude-done-notify'
if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }

# Register the claude-notify: protocol (idempotent, HKCU = no admin needed) so a
# toast click can run focus-terminal.ps1 even after this process has exited.
# The click goes through a wscript shim: launching powershell.exe directly
# flashes a console window that disturbs the focus handoff.
$handler = Join-Path $PSScriptRoot 'focus-terminal.ps1'
$shim = Join-Path $stateDir 'focus-launch.vbs'
$shimContent = "CreateObject(""WScript.Shell"").Run ""powershell.exe -NoProfile -ExecutionPolicy Bypass -File """"$handler"""""", 0, False"
if (-not (Test-Path $shim) -or (Get-Content $shim -Raw -ErrorAction SilentlyContinue).Trim() -ne $shimContent) {
    Set-Content -Path $shim -Value $shimContent -Encoding ASCII
}
$protoKey = 'HKCU:\Software\Classes\claude-notify'
$cmdKey = "$protoKey\shell\open\command"
$cmdVal = "wscript.exe `"$shim`" `"%1`""
if ((Get-ItemProperty -Path $cmdKey -ErrorAction SilentlyContinue).'(default)' -ne $cmdVal) {
    New-Item -Path $protoKey -Force | Out-Null
    Set-ItemProperty -Path $protoKey -Name '(default)' -Value 'URL:Claude Notify'
    Set-ItemProperty -Path $protoKey -Name 'URL Protocol' -Value ''
    New-Item -Path $cmdKey -Force | Out-Null
    Set-ItemProperty -Path $cmdKey -Name '(default)' -Value $cmdVal
}

# Find the terminal window Claude is running in and remember its handle for the click.
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class ConWin {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("kernel32.dll")] public static extern bool AttachConsole(uint pid);
    [DllImport("kernel32.dll")] public static extern bool FreeConsole();
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
}
"@

# Collect the ancestor chain: notify-powershell <- bash <- claude <- shell <- terminal host
$ancestors = @()
$procId = $PID
for ($i = 0; $i -lt 15 -and $procId; $i++) {
    $ancestors += $procId
    $procId = (Get-CimInstance Win32_Process -Filter "ProcessId=$procId" -ErrorAction SilentlyContinue).ParentProcessId
}

$hwnd = [int64]0

# Pass 1: GUI terminal hosts (Windows Terminal, VS Code, ...) appear in the
# chain as a process owning a visible top-level window.
# Skip shell/desktop procs: when Claude is launched from Explorer (shortcut,
# Win+R, double-click) explorer.exe is an ancestor and its visible shell window
# would be wrongly grabbed here, shadowing the real console found in Pass 2.
$nonTerminal = @('explorer', 'dwm', 'sihost', 'ShellExperienceHost', 'StartMenuExperienceHost', 'SearchHost', 'ApplicationFrameHost')
foreach ($id in $ancestors) {
    $proc = Get-Process -Id $id -ErrorAction SilentlyContinue
    if ($proc -and $proc.ProcessName -in $nonTerminal) { continue }
    if ($proc -and $proc.MainWindowHandle -ne [IntPtr]::Zero -and [ConWin]::IsWindowVisible($proc.MainWindowHandle)) {
        $hwnd = [int64]$proc.MainWindowHandle; break
    }
}

# Pass 2: classic console (plain powershell/cmd window). The window belongs to
# conhost.exe, which is not an ancestor - attach to each ancestor's console and
# ask for its window. In Windows Terminal the pty conhost window is invisible,
# so the visibility check keeps pass 1 results authoritative.
if ($hwnd -eq 0) {
    foreach ($id in $ancestors) {
        if ($id -eq $PID) { continue }
        [ConWin]::FreeConsole() | Out-Null
        if ([ConWin]::AttachConsole([uint32]$id)) {
            $h = [ConWin]::GetConsoleWindow()
            [ConWin]::FreeConsole() | Out-Null
            if ($h -ne [IntPtr]::Zero -and [ConWin]::IsWindowVisible($h)) { $hwnd = [int64]$h; break }
        }
    }
}

# Pass 3: last resort - any visible Windows Terminal window
if ($hwnd -eq 0) {
    $proc = Get-Process WindowsTerminal -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } | Select-Object -First 1
    if ($proc) { $hwnd = [int64]$proc.MainWindowHandle }
}
Set-Content -Path (Join-Path $stateDir 'focus-target.txt') -Value $hwnd

# Show a Windows toast notification (click -> claude-notify:focus -> focus-terminal.ps1).
# Skipped when the animated overlay is enabled - the overlay is the notification
# then, and clicking it focuses the terminal via the same focus-target mechanism.
if ($animEnabled) { return }
try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

    $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'

    $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
    $texts = $template.GetElementsByTagName('text')
    $texts.Item(0).AppendChild($template.CreateTextNode('Claude Code')) | Out-Null
    $texts.Item(1).AppendChild($template.CreateTextNode($Message)) | Out-Null

    $root = $template.DocumentElement
    $root.SetAttribute('activationType', 'protocol')
    $root.SetAttribute('launch', 'claude-notify:focus')

    $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
} catch {
    # Toast failed (e.g. notifications disabled) - the sound above still fired
}
