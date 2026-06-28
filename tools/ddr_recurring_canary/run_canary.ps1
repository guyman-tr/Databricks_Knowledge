<#
    Daily wrapper for the DDR recurring-investment decoupling canary.
    Registered as a Windows Scheduled Task (see README). Logs to out\logs\<date>.log
    and lets check.py send the AgentMail status itself.
#>
param(
    [switch]$NoEmail,        # local dry run
    [switch]$AlertOnly       # email only on WARN/FAIL (default: daily heartbeat)
)

$ErrorActionPreference = "Stop"
$here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $here "..\..")).Path
$logDir   = Join-Path $here "out\logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir ((Get-Date -Format "yyyy-MM-dd") + ".log")

# Same auth profile as the Cursor Databricks MCP
if (-not $env:DATABRICKS_MCP_PROFILE) { $env:DATABRICKS_MCP_PROFILE = "guyman" }

# The SDK's databricks-cli OAuth strategy needs the UNIFIED CLI (>=0.200) ahead of the
# legacy 0.18 CLI on PATH, otherwise headless auth fails with "cannot configure default
# credentials". Prepend the unified CLI dir if present.
$unifiedCli = Join-Path $env:LOCALAPPDATA "DatabricksCLI"
if (Test-Path (Join-Path $unifiedCli "databricks.exe")) {
    $env:PATH = "$unifiedCli;$env:PATH"
}

$pyArgs = @("tools\ddr_recurring_canary\check.py")
if ($NoEmail)        { $pyArgs += "--no-email" }
elseif (-not $AlertOnly) { $pyArgs += "--always-email" }   # daily status heartbeat

Push-Location $repoRoot
try {
    "==== $(Get-Date -Format o) :: starting canary ====" | Tee-Object -FilePath $log -Append
    python -u @pyArgs *>&1 | Tee-Object -FilePath $log -Append
    $code = $LASTEXITCODE
    "==== exit code $code ====" | Tee-Object -FilePath $log -Append
    exit $code
}
finally {
    Pop-Location
}
