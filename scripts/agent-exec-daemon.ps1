# Agent command bridge: lets Cursor Agent run local commands via file queue
# Install once: powershell -File scripts\install-agent-exec.ps1

$ErrorActionPreference = "SilentlyContinue"
$QueueDir = Join-Path $env:USERPROFILE ".cursor\agent-exec"
$Request = Join-Path $QueueDir "request.cmd"
$Response = Join-Path $QueueDir "response.txt"
$Status = Join-Path $QueueDir "status.txt"
$Log = Join-Path $QueueDir "daemon.log"
$PollSec = 2

New-Item -ItemType Directory -Path $QueueDir -Force | Out-Null

function Log($m) {
    Add-Content -Path $Log -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $m"
}

Log "agent-exec-daemon started"

while ($true) {
    Start-Sleep -Seconds $PollSec
    if (-not (Test-Path $Request)) { continue }

    $cmd = Get-Content $Request -Raw -ErrorAction SilentlyContinue
    if (-not $cmd) { continue }

    Remove-Item $Request -Force -ErrorAction SilentlyContinue
    Set-Content -Path $Status -Value "running"
    Log "exec: $cmd"

    try {
        $out = cmd /c "$cmd" 2>&1 | Out-String
        $code = $LASTEXITCODE
        @(
            "exit_code=$code",
            "--- output ---",
            $out
        ) | Set-Content -Path $Response -Encoding UTF8
        Set-Content -Path $Status -Value "done"
        Log "done exit=$code"
    }
    catch {
        Set-Content -Path $Response -Value ("exit_code=1`n--- output ---`n$($_.Exception.Message)")
        Set-Content -Path $Status -Value "error"
        Log "error: $($_.Exception.Message)"
    }
}
