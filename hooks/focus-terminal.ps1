# claude-notify: protocol handler - brings the terminal Claude ran in to the foreground.
param([string]$Uri)
$ErrorActionPreference = 'SilentlyContinue'

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Threading;
public class Win32Focus {
    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
    [DllImport("user32.dll")] static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("user32.dll")] static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] static extern void SwitchToThisWindow(IntPtr hWnd, bool fAltTab);
    [DllImport("user32.dll")] static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();

    // After a toast click, Windows runs its own focus transition that can undo a
    // naive SetForegroundWindow (the terminal pops up, then minimizes again).
    // Keep re-asserting focus until the window has HELD the foreground for
    // several consecutive checks; give up after ~3 seconds.
    public static bool ForceFocus(IntPtr h) {
        Thread.Sleep(250);
        int stable = 0;
        for (int i = 0; i < 20; i++) {
            if (GetForegroundWindow() == h && !IsIconic(h)) {
                stable++;
                if (stable >= 3) return true;
            } else {
                stable = 0;
                if (IsIconic(h)) ShowWindowAsync(h, 9); // SW_RESTORE
                keybd_event(0x12, 0, 0, UIntPtr.Zero);  // Alt tap: releases the foreground lock
                keybd_event(0x12, 0, 2, UIntPtr.Zero);
                IntPtr fg = GetForegroundWindow();
                uint pid;
                uint fgThread = GetWindowThreadProcessId(fg, out pid);
                uint cur = GetCurrentThreadId();
                AttachThreadInput(cur, fgThread, true);
                BringWindowToTop(h);
                SetForegroundWindow(h);
                AttachThreadInput(cur, fgThread, false);
                SwitchToThisWindow(h, true);            // Alt-Tab semantics: strongest activator
            }
            Thread.Sleep(150);
        }
        return false;
    }
}
"@

$stateFile = Join-Path $env:LOCALAPPDATA 'claude-done-notify\focus-target.txt'
$hwnd = [int64]0
if (Test-Path $stateFile) { $hwnd = [int64](Get-Content $stateFile -TotalCount 1) }

$h = [IntPtr]$hwnd
if ($hwnd -ne 0 -and [Win32Focus]::IsWindow($h)) {
    [Win32Focus]::ForceFocus($h) | Out-Null
} else {
    # Saved window is gone - fall back to any terminal-ish window
    $proc = Get-Process WindowsTerminal, Code, powershell, pwsh, cmd -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } | Select-Object -First 1
    if ($proc) { [Win32Focus]::ForceFocus($proc.MainWindowHandle) | Out-Null }
}
