[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]  [string] $Schema,
    [Parameter(Mandatory=$true)]  [string] $ObjectName,
    [Parameter(Mandatory=$false)] [int]    $MaxAttempts = 2,
    [Parameter(Mandatory=$false)] [int]    $WriterTimeoutSeconds = 2400,
    [Parameter(Mandatory=$false)] [int]    $JudgeTimeoutSeconds = 900,
    [Parameter(Mandatory=$false)] [switch] $SkipPreload,
    [Parameter(Mandatory=$false)] [switch] $RunCompare,
    [Parameter(Mandatory=$false)] [string] $WriterModel = "",   # "" = claude.cmd default (Opus). "sonnet" / "opus" / full model ID accepted. Manual override knob.
    [Parameter(Mandatory=$false)] [string] $JudgeModel  = "",   # "" = claude.cmd default (Opus). Manual override knob.
    [Parameter(Mandatory=$false)] [switch] $NoLiveWrite          # suppress writing the best attempt into knowledge/synapse/Wiki/ (default = always write directly)
)

# ---------------------------------------------------------------------------
# Regen harness orchestrator for a single object.
#
# Pipeline:
#   1. preload_upstream.py        (deterministic upstream resolution)
#   2. build_writer_prompt.py     (compose attempt N prompt)
#   3. run_writer.ps1             (claude #1 -- writer)
#   4. run_judge.ps1              (claude #2 -- judge, fresh context)
#   5. If verdict == FAIL and attempts remain: feed judge feedback back into
#      build_writer_prompt.py and rerun writer + judge once.
#   6. Symlink (or copy) the best attempt into regen/final/.
#   7. Optionally run compare_one.py to produce compare.md.
#
# All outputs land under audits/regen-sample/{Schema}/{Object}/. The main wiki
# tree is never touched.
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'
$harnessRoot = Split-Path -Parent $PSCommandPath
$repoRoot = (Get-Item (Join-Path $harnessRoot "..\..\")).FullName

$objDir       = Join-Path $repoRoot ("audits\regen-sample\{0}\{1}" -f $Schema, $ObjectName)
$regenDir     = Join-Path $objDir "regen"
$currentDir   = Join-Path $objDir "current"
$finalDir     = Join-Path $regenDir "final"
$bundlePath   = Join-Path $regenDir "_upstream_bundle.md"

if (-not (Test-Path $objDir)) {
    Write-Host "ERROR: object folder missing: $objDir" -ForegroundColor Red
    Write-Host "Run pick_sample.py first to populate the side folder." -ForegroundColor Red
    exit 1
}

$logHeader = ("==== {0}.{1} ====" -f $Schema, $ObjectName)
Write-Host ""
Write-Host $logHeader -ForegroundColor Magenta
Write-Host ("    Object dir: {0}" -f $objDir) -ForegroundColor DarkGray
Write-Host ""

# ---------- 1. Preload upstream (deterministic, no LLM) ----------
if (-not $SkipPreload -or -not (Test-Path $bundlePath)) {
    Write-Host "  [1/5] preload_upstream.py" -ForegroundColor Yellow
    & python (Join-Path $harnessRoot "preload_upstream.py") --schema $Schema --object $ObjectName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  preload_upstream.py FAILED" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  [1/5] preload_upstream.py SKIPPED (bundle already present)" -ForegroundColor DarkGray
}

if (-not (Test-Path $bundlePath)) {
    Write-Host "  ERROR: _upstream_bundle.md still missing after preload." -ForegroundColor Red
    exit 1
}

# ---------- 2-5. Writer + Judge loop ----------
$bestAttempt = 0
$bestScore = -1.0
$attemptResults = @()

for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    $attemptDir = Join-Path $regenDir ("attempt_{0}" -f $attempt)
    New-Item -ItemType Directory -Path $attemptDir -Force | Out-Null

    Write-Host ""
    Write-Host ("  [Attempt {0}/{1}]" -f $attempt, $MaxAttempts) -ForegroundColor Yellow
    Write-Host ("  [2/5] build_writer_prompt.py (attempt {0})" -f $attempt) -ForegroundColor Yellow

    $buildArgs = @("--schema", $Schema, "--object", $ObjectName, "--attempt", $attempt)
    if ($attempt -gt 1) {
        $prevVerdict = Join-Path $regenDir ("attempt_{0}\judge_verdict.json" -f ($attempt - 1))
        if (Test-Path $prevVerdict) {
            $buildArgs += @("--judge-feedback", $prevVerdict)
        }
    }
    & python (Join-Path $harnessRoot "build_writer_prompt.py") @buildArgs
    if ($LASTEXITCODE -ne 0) { Write-Host "  build_writer_prompt.py FAILED" -ForegroundColor Red; exit 1 }

    Write-Host ("  [3/5] run_writer.ps1 (attempt {0})" -f $attempt) -ForegroundColor Yellow
    & (Join-Path $harnessRoot "run_writer.ps1") `
        -Schema $Schema `
        -ObjectName $ObjectName `
        -Attempt $attempt `
        -TimeoutSeconds $WriterTimeoutSeconds `
        -Model $WriterModel
    $writerExit = $LASTEXITCODE
    if ($writerExit -ne 0) {
        Write-Host ("  Writer attempt {0} FAILED (exit {1}). Skipping judge for this attempt." -f $attempt, $writerExit) -ForegroundColor Red
        $attemptResults += [pscustomobject]@{
            attempt = $attempt
            writer_exit = $writerExit
            verdict = "WRITER_FAILED"
            score = $null
        }
        continue
    }

    # Locate the writer-produced files for the judge
    $wikiPath    = Join-Path $attemptDir ("{0}.md" -f $ObjectName)
    $lineagePath = Join-Path $attemptDir ("{0}.lineage.md" -f $ObjectName)
    $reviewPath  = Join-Path $attemptDir ("{0}.review-needed.md" -f $ObjectName)
    $ddlPath = $null
    foreach ($sub in @("Tables", "Views", "Functions")) {
        $cand = Join-Path "c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we" ("{0}\{1}\{0}.{2}.sql" -f $Schema, $sub, $ObjectName)
        if (Test-Path $cand) { $ddlPath = $cand; break }
    }
    if (-not $ddlPath) {
        Write-Host "  WARN: DDL not located in SSDT -- passing /dev/null-equivalent to judge" -ForegroundColor Yellow
        $ddlPath = Join-Path $attemptDir "_no_ddl.txt"
        "(DDL not found in DataPlatform SSDT)" | Out-File -FilePath $ddlPath -Encoding utf8
    }

    Write-Host ("  [4/5] run_judge.ps1 (attempt {0})" -f $attempt) -ForegroundColor Yellow
    & (Join-Path $harnessRoot "run_judge.ps1") `
        -Schema $Schema `
        -ObjectName $ObjectName `
        -WikiPath $wikiPath `
        -LineagePath $lineagePath `
        -ReviewPath $reviewPath `
        -DdlPath $ddlPath `
        -UpstreamBundlePath $bundlePath `
        -OutDir $attemptDir `
        -TimeoutSeconds $JudgeTimeoutSeconds `
        -Model $JudgeModel
    $judgeExit = $LASTEXITCODE

    $verdictPath = Join-Path $attemptDir "judge_verdict.json"
    $verdictObj = $null
    $score = $null
    $verdictStr = "UNKNOWN"
    if (Test-Path $verdictPath) {
        try {
            $verdictObj = Get-Content $verdictPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($verdictObj.verdict) {
                $score = $verdictObj.verdict.weighted_score
                $verdictStr = $verdictObj.verdict.verdict
            } elseif ($verdictObj.parse_error) {
                $verdictStr = "PARSE_ERROR"
            }
        } catch {}
    }

    Write-Host ("  Attempt {0} verdict: {1} (score {2})" -f $attempt, $verdictStr, $score) -ForegroundColor Cyan

    $attemptResults += [pscustomobject]@{
        attempt = $attempt
        writer_exit = 0
        judge_exit = $judgeExit
        verdict = $verdictStr
        score = $score
    }

    if ($score -ne $null -and $score -gt $bestScore) {
        $bestScore = [double]$score
        $bestAttempt = $attempt
    } elseif ($bestAttempt -eq 0) {
        # First attempt with no parseable score -- still record it as best so we copy *something* into final/
        $bestAttempt = $attempt
    }

    if ($verdictStr -eq "PASS") {
        Write-Host "  Judge PASSED -- stopping retry loop early." -ForegroundColor Green
        break
    }
}

# ---------- 6. Copy best attempt into final/ AND directly into the live wiki tree ----------
# Two writes happen here:
#   6a. Audit copy: attempt_N/* -> regen/final/  (forensic snapshot for compare/judge tooling)
#   6b. Live write: best attempt's 3 user-facing files -> knowledge/synapse/Wiki/{Schema}/{sub}/
#       The live write happens unconditionally (default behaviour). Pass -NoLiveWrite to suppress.
#       If a file already exists in the live tree, it is backed up to <name>.bak before overwrite
#       (single generation kept).
if ($bestAttempt -gt 0) {
    $bestDir = Join-Path $regenDir ("attempt_{0}" -f $bestAttempt)

    # --- 6a. Forensic copy into regen/final/ ---
    Remove-Item $finalDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $finalDir -Force | Out-Null
    foreach ($pat in @("*.md", "*.json", "*.jsonl")) {
        Get-ChildItem $bestDir -Filter $pat -ErrorAction SilentlyContinue | ForEach-Object {
            Copy-Item $_.FullName -Destination (Join-Path $finalDir $_.Name) -Force
        }
    }
    Write-Host ("  Final attempt copied: attempt_{0} -> final/  (score {1})" -f $bestAttempt, $bestScore) -ForegroundColor Green

    # --- 6b. Direct write into the live knowledge tree ---
    if (-not $NoLiveWrite) {
        $liveWikiRoot = Join-Path $repoRoot "knowledge\synapse\Wiki"
        $liveDir = $null
        foreach ($sub in @("Tables", "Views", "Functions")) {
            $candFile = Join-Path $liveWikiRoot ("{0}\{1}\{2}.md" -f $Schema, $sub, $ObjectName)
            if (Test-Path $candFile) { $liveDir = Split-Path -Parent $candFile; break }
        }
        if (-not $liveDir) {
            # No existing live wiki -- default to Tables/. Caller can move to Views/Functions later.
            $liveDir = Join-Path $liveWikiRoot ("{0}\Tables" -f $Schema)
            New-Item -ItemType Directory -Path $liveDir -Force | Out-Null
        }
        Write-Host ("  Writing live wiki -> {0}" -f $liveDir) -ForegroundColor Green
        foreach ($suffix in @(".md", ".lineage.md", ".review-needed.md")) {
            $src = Join-Path $bestDir ("{0}{1}" -f $ObjectName, $suffix)
            if (-not (Test-Path $src)) { continue }
            $dst = Join-Path $liveDir ("{0}{1}" -f $ObjectName, $suffix)
            $existed = Test-Path $dst
            if ($existed) { Copy-Item -Path $dst -Destination "$dst.bak" -Force }
            Copy-Item -Path $src -Destination $dst -Force
            $tag = if ($existed) { "(replaced; .bak written)" } else { "(new)" }
            Write-Host ("    {0,-50} {1}" -f (Split-Path -Leaf $dst), $tag) -ForegroundColor Green
        }
    } else {
        Write-Host "  -NoLiveWrite set: live wiki tree NOT touched (best attempt sits in regen/final/)." -ForegroundColor DarkGray
    }
} else {
    Write-Host "  No usable attempt produced -- nothing copied to final/ or live tree." -ForegroundColor Red
}

# ---------- Save per-object orchestrator summary ----------
$summary = [ordered]@{
    schema = $Schema
    object = $ObjectName
    best_attempt = $bestAttempt
    best_score = $bestScore
    attempts = $attemptResults
    timestamp = (Get-Date).ToString("o")
}
[System.IO.File]::WriteAllText(
    (Join-Path $regenDir "regen_summary.json"),
    ($summary | ConvertTo-Json -Depth 10),
    [System.Text.UTF8Encoding]::new($false)
)

# ---------- 7. Optional compare ----------
if ($RunCompare) {
    Write-Host "  [5/5] compare_one.py" -ForegroundColor Yellow
    & python (Join-Path $harnessRoot "compare_one.py") --schema $Schema --object $ObjectName
}

Write-Host ""
exit 0
