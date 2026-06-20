# Queue a command for agent-exec-daemon (used by Agent via writing request.cmd directly)
param(
    [Parameter(Mandatory = $true)]
    [string]$Command
)

$QueueDir = Join-Path $env:USERPROFILE ".cursor\agent-exec"
$Request = Join-Path $QueueDir "request.cmd"
$Response = Join-Path $QueueDir "response.txt"
$Status = Join-Path $QueueDir "status.txt"

New-Item -ItemType Directory -Path $QueueDir -Force | Out-Null
Remove-Item $Response -Force -ErrorAction SilentlyContinue
Set-Content -Path $Status -Value "pending"
Set-Content -Path $Request -Value $Command -Encoding ASCII

Write-Host "Queued. Wait for daemon (status.txt -> done)."
Write-Host "Response: $Response"
