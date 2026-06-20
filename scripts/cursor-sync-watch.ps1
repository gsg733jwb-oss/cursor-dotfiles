# Poll Cursor config dirs and trigger debounced push (Windows peer)
$ErrorActionPreference = "SilentlyContinue"

$Dotfiles = Join-Path $env:USERPROFILE "cursor-dotfiles"
$Auto = Join-Path $Dotfiles "scripts\cursor-sync-auto.ps1"
$Log = Join-Path $env:USERPROFILE ".cursor\sync-auto.log"
$Interval = if ($env:CURSOR_SYNC_POLL) { [int]$env:CURSOR_SYNC_POLL } else { 10 }
$StateFile = Join-Path $env:USERPROFILE ".cursor\.sync-watch.state"
$CursorHome = Join-Path $env:USERPROFILE ".cursor"
$EditorUser = Join-Path $env:APPDATA "Cursor\User"

function Get-WatchSnapshot {
    $files = @()
    foreach ($dir in @("rules", "skills", "hooks")) {
        $p = Join-Path $CursorHome $dir
        if (Test-Path $p) { $files += Get-ChildItem $p -Recurse -File -ErrorAction SilentlyContinue }
    }
    foreach ($f in @("mcp.json", "hooks.json")) {
        $p = Join-Path $CursorHome $f
        if (Test-Path $p) { $files += Get-Item $p }
    }
    foreach ($f in @("settings.json", "keybindings.json")) {
        $p = Join-Path $EditorUser $f
        if (Test-Path $p) { $files += Get-Item $p }
    }
    ($files | ForEach-Object { "{0}|{1}" -f $_.FullName, $_.LastWriteTimeUtc.Ticks }) -join "`n"
}

Add-Content -Path $Log -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] cursor-sync-watch started (poll ${Interval}s)"
Set-Content -Path $StateFile -Value (Get-WatchSnapshot)

while ($true) {
    Start-Sleep -Seconds $Interval
    $current = Get-WatchSnapshot
    $previous = Get-Content $StateFile -Raw -ErrorAction SilentlyContinue
    if ($current -ne $previous) {
        Set-Content -Path $StateFile -Value $current
        Add-Content -Path $Log -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] config change detected"
        & $Auto
    }
}
