# Claude Code hook: Windows sound + animated overlay. Clicking the overlay focuses the terminal.
param(
    [string]$Message = 'Job done - Claude has finished working.'
)
$ErrorActionPreference = 'SilentlyContinue'

# Play a notification sound.
[System.Media.SystemSounds]::Exclamation.Play()

# Animated overlay (bottom-right, click to focus terminal). Runs detached.
$anim = Join-Path $PSScriptRoot 'notify-anim.ps1'
if (Test-Path $anim) {
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
using System.Text;
public class ConWin {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("kernel32.dll")] public static extern bool AttachConsole(uint pid);
    [DllImport("kernel32.dll")] public static extern bool FreeConsole();
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
    // A console hosted by Windows Terminal (or any ConPTY, incl. VS Code) reports
    // an invisible 0x0 'PseudoConsoleWindow' - a real HWND that is NOT the window
    // the user sees. Reject it so detection falls through to the GUI-host passes.
    public static bool IsRealConsole(IntPtr h) {
        var sb = new StringBuilder(64);
        GetClassName(h, sb, 64);
        return sb.ToString() != "PseudoConsoleWindow";
    }
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
            if ($h -ne [IntPtr]::Zero -and [ConWin]::IsWindowVisible($h) -and [ConWin]::IsRealConsole($h)) { $hwnd = [int64]$h; break }
        }
    }
}

# Pass 3: last resort - any visible Windows Terminal window
if ($hwnd -eq 0) {
    $proc = Get-Process WindowsTerminal -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } | Select-Object -First 1
    if ($proc) { $hwnd = [int64]$proc.MainWindowHandle }
}
Set-Content -Path (Join-Path $stateDir 'focus-target.txt') -Value $hwnd

# The animated overlay (launched above) is the notification; clicking it fires
# claude-notify:focus -> focus-terminal.ps1, which reads focus-target.txt.
