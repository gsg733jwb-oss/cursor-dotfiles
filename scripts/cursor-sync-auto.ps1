# Debounced auto push to Gitee (Windows peer)
$ErrorActionPreference = "SilentlyContinue"

$Dotfiles = Join-Path $env:USERPROFILE "cursor-dotfiles"
$Log = Join-Path $env:USERPROFILE ".cursor\sync-auto.log"
$TokenFile = Join-Path $env:USERPROFILE ".cursor\.sync-debounce.token"
$Suppress = Join-Path $env:USERPROFILE ".cursor\.sync-suppress"
$DebounceSec = if ($env:CURSOR_SYNC_DEBOUNCE) { [int]$env:CURSOR_SYNC_DEBOUNCE } else { 45 }

$cursorDir = Join-Path $env:USERPROFILE ".cursor"
if (-not (Test-Path $cursorDir)) { New-Item -ItemType Directory -Path $cursorDir -Force | Out-Null }

if (Test-Path $Suppress) { exit 0 }

$token = [Guid]::NewGuid().ToString()
Set-Content -Path $TokenFile -Value $token -NoNewline

$script = @"
Start-Sleep -Seconds $DebounceSec
if (Test-Path '$Suppress') { exit 0 }
if ((Get-Content '$TokenFile' -Raw -ErrorAction SilentlyContinue) -ne '$token') { exit 0 }
Add-Content -Path '$Log' -Value "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] auto push start"
& powershell -NoProfile -ExecutionPolicy Bypass -File '$Dotfiles\scripts\cursor-sync.ps1' push
Add-Content -Path '$Log' -Value "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] auto push done"
"@

Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -ArgumentList @(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $script
) | Out-Null

exit 0
