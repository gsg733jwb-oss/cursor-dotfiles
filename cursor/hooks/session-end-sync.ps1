$auto = Join-Path $env:USERPROFILE "cursor-dotfiles\scripts\cursor-sync-auto.ps1"
if (Test-Path $auto) {
    Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -ArgumentList @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $auto
    ) | Out-Null
}
exit 0
