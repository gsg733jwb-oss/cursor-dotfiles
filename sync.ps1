# cursor-dotfiles sync — Windows
# 三台机器只与 Gitee 同步；GitHub 由定时任务镜像，本机不 push GitHub
param(
    [Parameter(Position = 0)]
    [ValidateSet("pull", "push", "sync")]
    [string]$Command = "pull"
)

$ErrorActionPreference = "Stop"
$Dotfiles = Split-Path -Parent $MyInvocation.MyCommand.Path
$CursorHome = Join-Path $env:USERPROFILE ".cursor"
$EditorUser = Join-Path $env:APPDATA "Cursor\User"
$GitRemote = if ($env:GIT_REMOTE) { $env:GIT_REMOTE } else { "gitee" }

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

function Collect-FromLive {
    Ensure-Dirs
    Sync-Dir (Join-Path $CursorHome "rules") (Join-Path $Dotfiles "cursor\rules")
    if (Test-Path (Join-Path $CursorHome "skills")) {
        Sync-Dir (Join-Path $CursorHome "skills") (Join-Path $Dotfiles "cursor\skills")
    }
    $mcpLive = Join-Path $CursorHome "mcp.json"
    if (Test-Path $mcpLive) {
        Copy-Item $mcpLive (Join-Path $Dotfiles "cursor\mcp.json") -Force
    }
    if (Test-Path (Join-Path $CursorHome "hooks")) {
        $hooksDst = Join-Path $Dotfiles "cursor\hooks"
        if (-not (Test-Path $hooksDst)) { New-Item -ItemType Directory -Path $hooksDst -Force | Out-Null }
        Sync-Dir (Join-Path $CursorHome "hooks") $hooksDst
    }
    foreach ($f in @("settings.json", "keybindings.json")) {
        $src = Join-Path $EditorUser $f
        if (Test-Path $src) { Copy-Item $src (Join-Path $Dotfiles "editor\$f") -Force }
    }
    Write-Host "collected live config -> $Dotfiles"
}

function Apply-ToLive {
    Ensure-Dirs
    Sync-Dir (Join-Path $Dotfiles "cursor\rules") (Join-Path $CursorHome "rules")
    $skillsSrc = Join-Path $Dotfiles "cursor\skills"
    if ((Test-Path $skillsSrc) -and ((Get-ChildItem $skillsSrc -Force | Measure-Object).Count -gt 0)) {
        Sync-Dir $skillsSrc (Join-Path $CursorHome "skills")
    }
    $mcpSrc = Join-Path $Dotfiles "cursor\mcp.json"
    if (Test-Path $mcpSrc) { Copy-Item $mcpSrc (Join-Path $CursorHome "mcp.json") -Force }
    $hooksSrc = Join-Path $Dotfiles "cursor\hooks"
    if ((Test-Path $hooksSrc) -and ((Get-ChildItem $hooksSrc -Force | Measure-Object).Count -gt 0)) {
        $hooksDst = Join-Path $CursorHome "hooks"
        if (-not (Test-Path $hooksDst)) { New-Item -ItemType Directory -Path $hooksDst -Force | Out-Null }
        Sync-Dir $hooksSrc $hooksDst
    }
    if (-not (Test-Path $EditorUser)) { New-Item -ItemType Directory -Path $EditorUser -Force | Out-Null }
    foreach ($f in @("settings.json", "keybindings.json")) {
        $src = Join-Path $Dotfiles "editor\$f"
        if (Test-Path $src) { Copy-Item $src (Join-Path $EditorUser $f) -Force }
    }
    Write-Host "applied $Dotfiles -> live (~\.cursor + editor)"
}

function Git-Pull {
    Push-Location $Dotfiles
    try {
        git pull --rebase $GitRemote main 2>$null
        if ($LASTEXITCODE -ne 0) {
            git pull --rebase $GitRemote master 2>$null
            if ($LASTEXITCODE -ne 0) { git pull --rebase $GitRemote }
        }
    } finally { Pop-Location }
}

function Git-Push {
    Push-Location $Dotfiles
    try {
        git push $GitRemote main 2>$null
        if ($LASTEXITCODE -ne 0) {
            git push $GitRemote master 2>$null
            if ($LASTEXITCODE -ne 0) { git push $GitRemote HEAD }
        }
    } finally { Pop-Location }
}

function Pull-Remote { Git-Pull; Apply-ToLive }

function Push-Remote {
    Collect-FromLive
    Push-Location $Dotfiles
    try {
        git add -A
        git diff --staged --quiet
        if ($LASTEXITCODE -ne 0) {
            git commit -m "sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm') ($env:COMPUTERNAME)"
        } else { Write-Host "nothing to commit" }
    } finally { Pop-Location }
    Git-Pull
    Git-Push
    Write-Host "pushed to Gitee ($GitRemote) — GitHub 由定时镜像更新"
}

switch ($Command) {
    "pull" { Pull-Remote }
    "push" { Push-Remote }
    "sync" { Pull-Remote; Push-Remote }
}
