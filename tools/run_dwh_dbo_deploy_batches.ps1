# Loop DWH_dbo UC deploy in small batches (default 5) with a visible "batch done" banner + beep.
# Run from anywhere; changes to repo root first.
#
# Examples:
#   .\tools\run_dwh_dbo_deploy_batches.ps1
#   .\tools\run_dwh_dbo_deploy_batches.ps1 -Verbose
#   .\tools\run_dwh_dbo_deploy_batches.ps1 -BatchSize 5 -MaxSecondsPerBatch 900

param(
    [int] $BatchSize = 5,
    [int] $StartBatch = 1,
    [int] $MaxSecondsPerBatch = 0,
    [double] $PauseSeconds = 2.0,
    [switch] $NoBeep,
    [switch] $Verbose
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $RepoRoot

$py = Join-Path $RepoRoot "tools\run_dwh_dbo_deploy_batches.py"
$argsList = @(
    "--batch-size", "$BatchSize",
    "--start-batch", "$StartBatch",
    "--pause-seconds", "$PauseSeconds"
)
if ($MaxSecondsPerBatch -gt 0) {
    $argsList += @("--max-seconds-per-batch", "$MaxSecondsPerBatch")
}
if ($NoBeep) { $argsList += "--no-beep" }
if ($Verbose) { $argsList += "-v" }

& python $py @argsList
exit $LASTEXITCODE
