# cursor-dotfiles sync — Windows（从机器，只 pull）
param(
    [Parameter(Position = 0)]
    [ValidateSet("pull")]
    [string]$Command = "pull"
)

$ErrorActionPreference = "Stop"
$Dotfiles = Split-Path -Parent $MyInvocation.MyCommand.Path
$CursorHome = Join-Path $env:USERPROFILE ".cursor"
$EditorUser = Join-Path $env:APPDATA "Cursor\User"

function Ensure-Dirs {
    @(
        (Join-Path $Dotfiles "cursor\rules"),
        (Join-Path $Dotfiles "cursor\skills"),
        (Join-Path $Dotfiles "cursor\hooks"),
        (Join-Path $Dotfiles "editor"),
        (Join-Path $CursorHome "rules"),
        (Join-Path $CursorHome "skills")
    ) | ForEach-Object {
        if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
    }
}

function Sync-Dir($From, $To) {
    if (-not (Test-Path $From)) { return }
    if (-not (Test-Path $To)) { New-Item -ItemType Directory -Path $To -Force | Out-Null }
    robocopy $From $To /MIR /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed: $From -> $To (exit $LASTEXITCODE)" }
    $global:LASTEXITCODE = 0
}

function Apply-ToLive {
    Ensure-Dirs

    Sync-Dir (Join-Path $Dotfiles "cursor\rules") (Join-Path $CursorHome "rules")

    $skillsSrc = Join-Path $Dotfiles "cursor\skills"
    if ((Test-Path $skillsSrc) -and ((Get-ChildItem $skillsSrc -Force | Measure-Object).Count -gt 0)) {
        Sync-Dir $skillsSrc (Join-Path $CursorHome "skills")
    }

    $mcpSrc = Join-Path $Dotfiles "cursor\mcp.json"
    if (Test-Path $mcpSrc) {
        Copy-Item $mcpSrc (Join-Path $CursorHome "mcp.json") -Force
    }

    $hooksSrc = Join-Path $Dotfiles "cursor\hooks"
    if ((Test-Path $hooksSrc) -and ((Get-ChildItem $hooksSrc -Force | Measure-Object).Count -gt 0)) {
        $hooksDst = Join-Path $CursorHome "hooks"
        if (-not (Test-Path $hooksDst)) { New-Item -ItemType Directory -Path $hooksDst -Force | Out-Null }
        Sync-Dir $hooksSrc $hooksDst
    }

    if (-not (Test-Path $EditorUser)) { New-Item -ItemType Directory -Path $EditorUser -Force | Out-Null }
    foreach ($f in @("settings.json", "keybindings.json")) {
        $src = Join-Path $Dotfiles "editor\$f"
        if (Test-Path $src) {
            Copy-Item $src (Join-Path $EditorUser $f) -Force
        }
    }

    Write-Host "applied $Dotfiles -> live (~\.cursor + editor)"
}

switch ($Command) {
    "pull" { Apply-ToLive }
}
