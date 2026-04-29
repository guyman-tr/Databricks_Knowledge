<#
.SYNOPSIS
  Auto-promote a regenerated wiki to the live tree when judge score >= threshold.

.DESCRIPTION
  Orchestrator-callable script that complements the human-facing
  promote_regen.ps1. Reads regen/final/judge_verdict.json (NOT compare.md),
  applies a score-threshold gate, and copies the regen .md (+ .lineage.md +
  .review-needed.md if present) over the live wiki tree. Any pre-existing
  live file is backed up to a timestamped .bak.<UTC>.md sidecar BEFORE
  overwrite (multi-generation; never destroys backup history).

  This script is opt-in via -EnableAutoPromote on regen_one.ps1; it never
  runs by default. The default threshold (9.0) is intentionally
  conservative -- judge scores in [9.0, 10.0] correspond to the judge's
  PASS verdict with no high-severity issues raised.

  Exit codes (machine-readable):
    0  promoted (live tree updated)
    1  score below threshold OR judge verdict missing/unparseable
    2  no live wiki found (cannot promote on top of nothing)
    3  regen/final dir or wiki .md missing
    4  hard error (caught at the top)

.PARAMETER Schema
  Synapse schema, e.g. BI_DB_dbo

.PARAMETER ObjectName
  Object name without schema, e.g. BI_DB_DailyZeroPnL_Stocks

.PARAMETER MinScore
  Minimum weighted_score from judge_verdict.json to trigger promotion.
  Default 9.0. Pass 0.0 to promote any PASS verdict (NOT recommended
  unless you trust the judge's stricter checks completely).

.PARAMETER RequirePassVerdict
  When set (default), require verdict.verdict == "PASS" in addition to
  the score threshold. Pass -RequirePassVerdict:$false to promote on
  score alone (e.g. for synthetic auto_verify verdicts).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]  [string] $Schema,
    [Parameter(Mandatory=$true)]  [string] $ObjectName,
    [Parameter(Mandatory=$false)] [double] $MinScore = 9.0,
    [Parameter(Mandatory=$false)] [bool]   $RequirePassVerdict = $true
)

$ErrorActionPreference = 'Stop'
$harnessRoot = Split-Path -Parent $PSCommandPath
$repoRoot = (Get-Item (Join-Path $harnessRoot "..\..\")).FullName
$wikiRoot  = Join-Path $repoRoot "knowledge\synapse\Wiki"
$auditRoot = Join-Path $repoRoot "audits\regen-sample"

$objAuditDir = Join-Path $auditRoot ("{0}\{1}" -f $Schema, $ObjectName)
$finalDir    = Join-Path $objAuditDir "regen\final"
$verdictPath = Join-Path $finalDir "judge_verdict.json"

$logHeader = ("==== AUTO-PROMOTE  {0}.{1} ====" -f $Schema, $ObjectName)
Write-Host ""
Write-Host $logHeader -ForegroundColor Magenta

if (-not (Test-Path $finalDir)) {
    Write-Host ("  SKIP: regen/final missing at {0}" -f $finalDir) -ForegroundColor Yellow
    exit 3
}

$srcWiki = Join-Path $finalDir ("{0}.md" -f $ObjectName)
if (-not (Test-Path $srcWiki)) {
    Write-Host ("  SKIP: regen wiki missing at {0}" -f $srcWiki) -ForegroundColor Yellow
    exit 3
}

# ---------- Read verdict ----------
if (-not (Test-Path $verdictPath)) {
    Write-Host ("  SKIP: judge_verdict.json missing at {0}" -f $verdictPath) -ForegroundColor Yellow
    exit 1
}
$verdictRaw = Get-Content $verdictPath -Raw -Encoding UTF8
try {
    $verdictObj = $verdictRaw | ConvertFrom-Json
} catch {
    Write-Host ("  SKIP: cannot parse judge_verdict.json: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    exit 1
}

$score = $null
$verdictStr = "UNKNOWN"
$autoVerified = $false
if ($verdictObj.verdict) {
    $score = $verdictObj.verdict.weighted_score
    $verdictStr = "$($verdictObj.verdict.verdict)"
    if ($verdictObj.verdict.PSObject.Properties.Name -contains 'auto_verified') {
        $autoVerified = [bool]$verdictObj.verdict.auto_verified
    }
}

if ($score -eq $null) {
    Write-Host "  SKIP: no weighted_score in verdict" -ForegroundColor Yellow
    exit 1
}

$scoreD = [double]$score
Write-Host ("  Verdict: {0}  Score: {1}  AutoVerified: {2}  Threshold: {3}" -f `
    $verdictStr, $scoreD, $autoVerified, $MinScore) -ForegroundColor Cyan

if ($RequirePassVerdict -and $verdictStr -ne "PASS") {
    Write-Host ("  SKIP: verdict {0} is not PASS (require-pass-verdict on)" -f $verdictStr) -ForegroundColor Yellow
    exit 1
}
if ($scoreD -lt $MinScore) {
    Write-Host ("  SKIP: score {0} below threshold {1}" -f $scoreD, $MinScore) -ForegroundColor Yellow
    exit 1
}

# ---------- Find live wiki dir ----------
$liveDir = $null
$liveSubdir = $null
foreach ($sub in @("Tables","Views","Functions")) {
    $cand = Join-Path $wikiRoot ("{0}\{1}\{2}.md" -f $Schema, $sub, $ObjectName)
    if (Test-Path $cand) {
        $liveDir = Split-Path -Parent $cand
        $liveSubdir = $sub
        break
    }
}
if (-not $liveDir) {
    Write-Host ("  SKIP: no live wiki found in any of Tables/Views/Functions for {0}.{1}" -f $Schema, $ObjectName) -ForegroundColor Yellow
    Write-Host  "         (auto-promote refuses to create new live wikis -- use promote_regen.ps1 with -Apply for new objects)"
    exit 2
}
Write-Host ("  Live dir: {0}  ({1})" -f $liveDir, $liveSubdir) -ForegroundColor Gray

# ---------- Promote with timestamped backup ----------
$ts = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
$promoted = @()
$backedUp = @()
foreach ($suffix in @(".md", ".lineage.md", ".review-needed.md")) {
    $src = Join-Path $finalDir ("{0}{1}" -f $ObjectName, $suffix)
    $dst = Join-Path $liveDir  ("{0}{1}" -f $ObjectName, $suffix)
    if (-not (Test-Path $src)) { continue }
    if (Test-Path $dst) {
        $bak = "$dst.bak.$ts"
        Copy-Item -Path $dst -Destination $bak -Force
        $backedUp += $bak
    }
    Copy-Item -Path $src -Destination $dst -Force
    $promoted += $dst
    Write-Host ("    wrote {0}" -f $dst) -ForegroundColor Green
}

# ---------- Write side-log ----------
$logEntry = [ordered]@{
    schema             = $Schema
    object             = $ObjectName
    timestamp          = (Get-Date).ToUniversalTime().ToString("o")
    score              = $scoreD
    verdict            = $verdictStr
    threshold          = $MinScore
    auto_verified      = $autoVerified
    require_pass       = $RequirePassVerdict
    promoted_files     = $promoted
    backups_created    = $backedUp
    live_subdir        = $liveSubdir
}
$logFile = Join-Path $objAuditDir "auto_promote_log.json"
[System.IO.File]::WriteAllText(
    $logFile,
    ($logEntry | ConvertTo-Json -Depth 6),
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host ("  PROMOTED -- {0} files written, {1} backups created. Log: {2}" -f `
    $promoted.Count, $backedUp.Count, $logFile) -ForegroundColor Green
exit 0
