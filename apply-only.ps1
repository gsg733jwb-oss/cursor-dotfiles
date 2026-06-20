# Apply cursor-dotfiles to live Cursor (Windows)
$Dotfiles = Join-Path $env:USERPROFILE "cursor-dotfiles"
$CursorHome = Join-Path $env:USERPROFILE ".cursor"
$EditorUser = Join-Path $env:APPDATA "Cursor\User"

function Sync-Dir($From, $To) {
    if (-not (Test-Path $From)) { return }
    if (-not (Test-Path $To)) { New-Item -ItemType Directory -Path $To -Force | Out-Null }
    robocopy $From $To /MIR /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed: $From -> $To" }
    $global:LASTEXITCODE = 0
}

Sync-Dir (Join-Path $Dotfiles "cursor\rules") (Join-Path $CursorHome "rules")

$skillsSrc = Join-Path $Dotfiles "cursor\skills"
if ((Test-Path $skillsSrc) -and ((Get-ChildItem $skillsSrc -Force -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)) {
    Sync-Dir $skillsSrc (Join-Path $CursorHome "skills")
}

$mcpSrc = Join-Path $Dotfiles "cursor\mcp.json"
if (Test-Path $mcpSrc) { Copy-Item $mcpSrc (Join-Path $CursorHome "mcp.json") -Force }

if (Test-Path (Join-Path $Dotfiles "cursor\hooks")) {
    Sync-Dir (Join-Path $Dotfiles "cursor\hooks") (Join-Path $CursorHome "hooks")
}

$hooksJson = Join-Path $Dotfiles "cursor\hooks.json"
if (Test-Path $hooksJson) { Copy-Item $hooksJson (Join-Path $CursorHome "hooks.json") -Force }

if (-not (Test-Path $EditorUser)) { New-Item -ItemType Directory -Path $EditorUser -Force | Out-Null }
foreach ($f in @("settings.json", "keybindings.json")) {
    $src = Join-Path $Dotfiles "editor\$f"
    if (Test-Path $src) { Copy-Item $src (Join-Path $EditorUser $f) -Force }
}

Write-Host "APPLY_DONE"
