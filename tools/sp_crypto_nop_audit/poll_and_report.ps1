param(
    [string]$Tag = "",            # e.g. "0400" or "0900"; default = current HHMM
    [string]$TargetDate = ""      # YYYY-MM-DD; default = yesterday
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Resolve-Path (Join-Path $ScriptDir "..\..")
$LogDir    = Join-Path $ScriptDir "logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

$Today   = (Get-Date).ToString("yyyy-MM-dd")
$LogFile = Join-Path $LogDir "$Today.log"

function Log {
    param([string]$msg)
    $line = "[{0}] {1}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $msg
    Add-Content -Path $LogFile -Value $line
    Write-Host $line
}

Log "=== START tag='$Tag' target='$TargetDate' cwd='$ScriptDir' ==="

# Build args
$pollArgs = @("$ScriptDir\poll_sources.py")
if ($Tag)        { $pollArgs += @("--tag", $Tag) }
if ($TargetDate) { $pollArgs += @("--target-date", $TargetDate) }

Log "Running: python $($pollArgs -join ' ')"
& python @pollArgs 2>&1 | ForEach-Object { Log $_ }
$pollExit = $LASTEXITCODE
Log "poll_sources.py exit=$pollExit"

# Always try to make report; it silently no-ops if only one snapshot exists.
$reportArgs = @("$ScriptDir\make_report.py")
if ($TargetDate) { $reportArgs += @("--target-date", $TargetDate) }

Log "Running: python $($reportArgs -join ' ')"
& python @reportArgs 2>&1 | ForEach-Object { Log $_ }
$reportExit = $LASTEXITCODE
Log "make_report.py exit=$reportExit"

Log "=== END  pollExit=$pollExit reportExit=$reportExit ==="
exit $pollExit
