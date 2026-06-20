# Install Windows background config watcher (optional, peer sync)
$ErrorActionPreference = "Stop"
$Dotfiles = Join-Path $env:USERPROFILE "cursor-dotfiles"
$Watch = Join-Path $Dotfiles "scripts\cursor-sync-watch.ps1"
$Startup = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $Startup "CursorConfigSync.lnk"

if (-not (Test-Path $Watch)) { throw "Missing $Watch" }

$wsh = New-Object -ComObject WScript.Shell
$lnk = $wsh.CreateShortcut($ShortcutPath)
$lnk.TargetPath = "powershell.exe"
$lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Watch`""
$lnk.WorkingDirectory = $Dotfiles
$lnk.Description = "Cursor dotfiles auto-sync (Gitee)"
$lnk.Save()

Write-Host "Installed startup watcher: $ShortcutPath"
Write-Host "Log: $env:USERPROFILE\.cursor\sync-auto.log"
