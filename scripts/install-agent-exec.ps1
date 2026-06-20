# Install agent-exec daemon to Windows Startup (run once)
$ErrorActionPreference = "Stop"
$Dotfiles = Join-Path $env:USERPROFILE "cursor-dotfiles"
$Daemon = Join-Path $Dotfiles "scripts\agent-exec-daemon.ps1"
$Startup = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $Startup "CursorAgentExec.lnk"

if (-not (Test-Path $Daemon)) { throw "Missing $Daemon" }

$wsh = New-Object -ComObject WScript.Shell
$lnk = $wsh.CreateShortcut($ShortcutPath)
$lnk.TargetPath = "powershell.exe"
$lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Daemon`""
$lnk.WorkingDirectory = $Dotfiles
$lnk.Description = "Cursor Agent command bridge"
$lnk.Save()

New-Item -ItemType Directory -Path (Join-Path $env:USERPROFILE ".cursor\agent-exec") -Force | Out-Null
Write-Host "Installed: $ShortcutPath"
Write-Host "Agent can queue commands to ~/.cursor/agent-exec/request.cmd"
