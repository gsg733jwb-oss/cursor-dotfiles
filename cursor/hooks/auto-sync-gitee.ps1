# Cursor hook: trigger debounced auto-push (Windows peer)
$ErrorActionPreference = "SilentlyContinue"
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }

try { $input = $raw | ConvertFrom-Json } catch { exit 0 }

$paths = @()
if ($input.file_path) { $paths += [string]$input.file_path }
if ($input.paths) { $paths += @($input.paths | ForEach-Object { [string]$_ }) }
if ($input.edits) {
    foreach ($e in $input.edits) {
        if ($e.path) { $paths += [string]$e.path }
    }
}

$watchPattern = '\\\.cursor\\(rules|skills|hooks)|\\\.cursor\\mcp\.json|\\Cursor\\User\\(settings|keybindings)\.json'
$matched = $false
foreach ($p in $paths) {
    if ($p -and ($p.Replace("/", "\") -match $watchPattern)) {
        $matched = $true
        break
    }
}
if (-not $matched) { exit 0 }

$auto = Join-Path $env:USERPROFILE "cursor-dotfiles\scripts\cursor-sync-auto.ps1"
if (-not (Test-Path $auto)) { exit 0 }

Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -ArgumentList @(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $auto
) | Out-Null

exit 0
