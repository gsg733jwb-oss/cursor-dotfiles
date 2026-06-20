# Gitee-only pull for Windows
$ErrorActionPreference = "Stop"
$Repo = Join-Path $env:USERPROFILE "cursor-dotfiles"
$Git = "C:\Program Files\Git\cmd\git.exe"
$env:GIT_REMOTE = "gitee"

Set-Location $Repo

& $Git stash push -m "win-temp" -- sync.ps1 pull-gitee.ps1 apply-only.ps1 2>$null | Out-Null

Write-Host "Pulling from Gitee..."
& $Git pull --rebase gitee main
if ($LASTEXITCODE -ne 0) { throw "git pull gitee main failed" }

& $Git log --oneline -1 | Write-Host

Write-Host "Applying to Cursor..."
& (Join-Path $Repo "apply-only.ps1")

& $Git stash pop 2>$null | Out-Null

Write-Host "Done (Gitee only)."
