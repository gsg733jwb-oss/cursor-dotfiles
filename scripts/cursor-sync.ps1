# pull / push wrapper: suppress auto-upload during pull
param(
    [Parameter(Position = 0)]
    [ValidateSet("pull", "push", "sync")]
    [string]$Action = "pull"
)

$ErrorActionPreference = "Stop"
$Dotfiles = Join-Path $env:USERPROFILE "cursor-dotfiles"
$Suppress = Join-Path $env:USERPROFILE ".cursor\.sync-suppress"
$SyncPs1 = Join-Path $Dotfiles "sync.ps1"

switch ($Action) {
    "pull" {
        $cursorDir = Join-Path $env:USERPROFILE ".cursor"
        if (-not (Test-Path $cursorDir)) { New-Item -ItemType Directory -Path $cursorDir -Force | Out-Null }
        New-Item -ItemType File -Path $Suppress -Force | Out-Null
        try {
            & (Join-Path $Dotfiles "pull-gitee.ps1")
        }
        finally {
            Remove-Item $Suppress -Force -ErrorAction SilentlyContinue
        }
    }
    "push" {
        & $SyncPs1 push
    }
    "sync" {
        & $PSCommandPath pull
        & $PSCommandPath push
    }
}
