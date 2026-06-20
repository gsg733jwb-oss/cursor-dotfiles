$Log = "$env:USERPROFILE\shougong.log"
function Log($m) { Add-Content $Log $m; Write-Host $m }

try {
    Log "=== shougong start $(Get-Date) ==="
    $Repo = "$env:USERPROFILE\cursor-dotfiles"
    $Git = "C:\Program Files\Git\cmd\git.exe"
    Set-Location $Repo

    Log "collect + push via sync.ps1..."
    & "$Repo\sync.ps1" push 2>&1 | ForEach-Object { Log $_ }

    Log "--- git log ---"
    & $Git log --oneline -3 2>&1 | ForEach-Object { Log $_ }
    Log "--- git status ---"
    & $Git status --short 2>&1 | ForEach-Object { Log $_ }
    Log "=== shougong done ==="
}
catch {
    Log "ERROR: $($_.Exception.Message)"
    exit 1
}
