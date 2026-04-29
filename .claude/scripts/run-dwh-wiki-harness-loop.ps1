# run-dwh-wiki-harness-loop.ps1
#
# New-pipeline wiki batch loop. Per-object writer + adversarial judge with
# hard retry, verdict-gated promotion to the live wiki tree. Strictly opt-in
# replacement for run-dwh-wiki-batch-loop.ps1 (which uses the legacy
# multi-object-per-iteration claude call).
#
# Differences vs legacy loop:
#   * Picks via Get-NextBatch with -AlterScopeOnly (lake-bound objects only).
#   * Calls tools/regen-harness/regen_one.ps1 once per object instead of
#     wrapping N objects into one batch prompt.
#   * Reads regen/final/judge_verdict.json after each object and either
#     promotes (verdict in $PromoteVerdicts) or leaves output in audits/
#     for manual review.
#   * No drift guard / Patch 1.5 check (the per-object judge gates quality).
#   * Same Synapse MCP pre-flight + startup sweep + rate-limit handling.
#
# Promotion semantics:
#   * Wiki + sidecars are copied from
#     audits/regen-sample/{Schema}/{Object}/regen/final/ to
#     knowledge/synapse/Wiki/{Schema}/{Tables|Views}/.
#   * Existing files (rare for newbuilds, common for regens) are backed up to
#     <name>.bak before overwrite.
#   * Failed objects are appended to
#     audits/regen-sample/_harness_loop_failed.txt for later triage.

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] [string]   $SchemaName       = "",
    [Parameter(Mandatory=$false)] [int]      $BatchSize        = 0,
    [Parameter(Mandatory=$false)] [string[]] $PromoteVerdicts  = @("PASS", "PARTIAL_PASS"),
    [Parameter(Mandatory=$false)] [int]      $MaxIterations    = 0,         # 0 = unlimited
    [Parameter(Mandatory=$false)] [int]      $MaxObjects       = 0,         # 0 = unlimited per loop run
    [Parameter(Mandatory=$false)] [int]      $WriterTimeout    = 2400,
    [Parameter(Mandatory=$false)] [int]      $JudgeTimeout     = 900,
    [Parameter(Mandatory=$false)] [switch]   $NoPromote,                    # leave everything in audits/ even on PASS
    [Parameter(Mandatory=$false)] [switch]   $DryRun,                       # show what would be picked, don't call regen_one

    # ── Cost-control levers (Lever 1: model routing) ────────────────────────
    # Writer model is chosen per object based on column count:
    #   cols <= $SimpleColThreshold  -> $WriterModelSimple
    #   cols >  $SimpleColThreshold  -> $WriterModelComplex
    # Setting either to "" falls back to claude.cmd default (currently Opus).
    # Judge always uses $JudgeModel (it's structural, doesn't need Opus).
    [Parameter(Mandatory=$false)] [string]   $WriterModelSimple  = "sonnet",
    [Parameter(Mandatory=$false)] [string]   $WriterModelComplex = "opus",
    [Parameter(Mandatory=$false)] [string]   $JudgeModel         = "sonnet",

    # ── Cost lever: skip the LLM judge for trivially-simple objects (cols<=N,
    #    single-mirror upstream, all rows passthrough). Wraps a deterministic
    #    pre-check + synthetic verdict so the loop stops calling claude-cli for
    #    cases where the judge always returns PASS anyway.
    [Parameter(Mandatory=$false)] [switch]   $EnableAutoVerify,
    [Parameter(Mandatory=$false)] [int]      $AutoVerifyMaxCols  = 5,

    # ── Workflow lever: auto-promote regen output to live wiki tree when judge
    #    score >= AutoPromoteMinScore. Backs up any existing live file to a
    #    timestamped .bak.<UTC>.md sidecar BEFORE overwrite. Off by default
    #    because new-object cases (no live wiki yet) intentionally require
    #    human triage via promote_regen.ps1 -Apply.
    [Parameter(Mandatory=$false)] [switch]   $EnableAutoPromote,
    [Parameter(Mandatory=$false)] [double]   $AutoPromoteMinScore = 9.0,
    [Parameter(Mandatory=$false)] [int]      $SimpleColThreshold = 30,

    # ── Throughput lever (T3: parallel regen_one) ───────────────────────────
    # Number of regen_one.ps1 invocations to run concurrently within a single
    # picked batch. Default 1 = serial (legacy behaviour). N>1 fans out via
    # PowerShell background jobs; per-object verdict/promote/rate-limit logic
    # runs as each job completes. Anthropic 5-h token quota is global, so
    # higher Parallelism burns the quota proportionally faster.
    [Parameter(Mandatory=$false)] [int]      $Parallelism        = 1
)

$ErrorActionPreference = 'Continue'

if (-not $SchemaName) {
    $SchemaName = Read-Host "Schema Name (default: BI_DB_dbo -- has the largest in-scope newbuild backlog)"
    if (-not $SchemaName) { $SchemaName = "BI_DB_dbo" }
}

$claudePath  = "$env:APPDATA\npm\claude.cmd"
$repoRoot    = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$harnessRoot = Join-Path $repoRoot "tools\regen-harness"
$regenOne    = Join-Path $harnessRoot "regen_one.ps1"
$wikiTables  = Join-Path $repoRoot "knowledge\synapse\Wiki\$SchemaName\Tables"
$wikiViews   = Join-Path $repoRoot "knowledge\synapse\Wiki\$SchemaName\Views"
$indexPath   = Join-Path $repoRoot "knowledge\synapse\Wiki\$SchemaName\_index.md"
$failedLog   = Join-Path $repoRoot "audits\regen-sample\_harness_loop_failed.txt"
$scopeJson   = Join-Path $repoRoot "audits\regen-sample\_alter_scope.json"

# Per-schema default batch size (wide net per iteration; harness picks one at a time).
if ($BatchSize -le 0) {
    $BatchSize = switch ($SchemaName) {
        "BI_DB_dbo"   { 8 }
        "DWH_dbo"     { 4 }
        "Dealing_dbo" { 4 }
        "eMoney_dbo"  { 6 }
        "EXW_dbo"     { 6 }
        default       { 4 }
    }
}

$libPath = Join-Path $PSScriptRoot "lib\Get-NextBatch.ps1"
if (-not (Test-Path $libPath)) {
    Write-Host "ERROR: Get-NextBatch.ps1 not found at $libPath" -ForegroundColor Red
    exit 1
}
. $libPath

if (-not (Test-Path $regenOne)) {
    Write-Host "ERROR: regen_one.ps1 not found at $regenOne" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $scopeJson)) {
    Write-Host "ERROR: _alter_scope.json not found at $scopeJson -- run tools\regen-harness\build_alter_scope.py first." -ForegroundColor Red
    exit 1
}
if (-not $DryRun -and -not (Test-Path $claudePath)) {
    Write-Host "ERROR: claude.cmd not found at $claudePath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Wiki Harness Loop (regen-harness pipeline, AlterScopeOnly)" -ForegroundColor Cyan
Write-Host "  Schema:   $SchemaName" -ForegroundColor Cyan
Write-Host "  Batch:    $BatchSize objects/iter (regen_one called serially)" -ForegroundColor Cyan
Write-Host "  Promote:  $($PromoteVerdicts -join ', ')$( if ($NoPromote) { '  (DISABLED via -NoPromote)' } )" -ForegroundColor Cyan
Write-Host "  Max iter: $( if ($MaxIterations -gt 0) { $MaxIterations } else { 'unlimited' } )" -ForegroundColor Cyan
Write-Host "  Max objs: $( if ($MaxObjects -gt 0) { $MaxObjects } else { 'unlimited' } )" -ForegroundColor Cyan
Write-Host ("  Parallel: {0} concurrent regen_one job(s) per batch" -f $Parallelism) -ForegroundColor Cyan
Write-Host ("  Writer:   simple<={0}cols -> {1}   complex>{0}cols -> {2}" -f `
    $SimpleColThreshold, `
    $(if ($WriterModelSimple)  { $WriterModelSimple }  else { '<default>' }), `
    $(if ($WriterModelComplex) { $WriterModelComplex } else { '<default>' })) -ForegroundColor Cyan
Write-Host ("  Judge:    {0}" -f $(if ($JudgeModel) { $JudgeModel } else { '<default>' })) -ForegroundColor Cyan
Write-Host ("  AutoVerify: {0}" -f $(if ($EnableAutoVerify) { "ON (max-trivial-cols={0})" -f $AutoVerifyMaxCols } else { "OFF (every object goes through LLM judge)" })) -ForegroundColor Cyan
Write-Host ("  AutoPromote: {0}" -f $(if ($EnableAutoPromote) { "ON (min-score={0}; live wiki updated in-place w/ .bak sidecar)" -f $AutoPromoteMinScore } else { "OFF (regen stays in audits/ tree -- run promote_regen.ps1 manually)" })) -ForegroundColor Cyan
Write-Host "  Repo:     $repoRoot" -ForegroundColor Cyan
Write-Host "  Started:  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  *** DRY-RUN: regen_one will NOT be called ***" -ForegroundColor Yellow
}
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ── PRE-FLIGHT: Synapse MCP connection ──────────────────────────────────────
# (Skipped in dry-run because regen_one isn't called; preflight in regen_one
# itself catches MCP issues per-object.)
if (-not $DryRun) {
    Write-Host "Pre-flight: testing Synapse MCP connection..." -ForegroundColor Yellow

    $mcpJson = Join-Path $env:USERPROFILE ".cursor\mcp.json"
    if (-not (Test-Path $mcpJson)) {
        $mcpJson = Join-Path $repoRoot ".mcp.json"
    }
    if (-not (Test-Path $mcpJson)) {
        Write-Host "HARD FAIL: mcp.json not found at ~/.cursor/mcp.json or $repoRoot\.mcp.json" -ForegroundColor Red
        exit 1
    }

    $mcpConfig  = Get-Content $mcpJson -Raw | ConvertFrom-Json
    $synEnv     = $mcpConfig.mcpServers.synapse_sql.env
    $testServer = if ($synEnv.SYNAPSE_SERVER) { $synEnv.SYNAPSE_SERVER } else { "stg-synapse-dataplatform-we.sql.azuresynapse.net" }
    $testDb     = if ($synEnv.SYNAPSE_DATABASE) { $synEnv.SYNAPSE_DATABASE } else { "sql_dp_stg_we_BI_no_retention" }

    $connTest = @"
import os, sys, pyodbc
SERVER = '$testServer'
DATABASE = '$testDb'
ENV_FILE = os.path.join(r'C:\Users\guyman\.cursor', 'synapse-credentials.env')
sql_user = os.environ.get('SYNAPSE_SQL_USER', '').strip() or None
sql_pass = os.environ.get('SYNAPSE_SQL_PASS', '').strip() or None
if not (sql_user and sql_pass) and os.path.exists(ENV_FILE):
    with open(ENV_FILE) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' in line:
                k, v = line.split('=', 1)
                k, v = k.strip(), v.strip()
                if k == 'SYNAPSE_SQL_USER' and v:
                    sql_user = v
                elif k == 'SYNAPSE_SQL_PASS' and v:
                    sql_pass = v
try:
    if sql_user and sql_pass:
        conn = pyodbc.connect(
            f'DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};'
            f'UID={sql_user};PWD={sql_pass};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=15',
            timeout=15)
        method = f'SQL auth ({sql_user})'
    else:
        import struct, msal
        cache_path = os.path.join(os.environ.get('LOCALAPPDATA', os.path.expanduser('~')), 'synapse-mcp-token-cache.bin')
        if not os.path.exists(cache_path):
            print('FAIL: No SQL creds and no MSAL token cache.', file=sys.stderr); sys.exit(1)
        cache = msal.SerializableTokenCache()
        cache.deserialize(open(cache_path).read())
        app = msal.PublicClientApplication('1950a258-227b-4e31-a9cf-717495945fc2',
              authority='https://login.microsoftonline.com/organizations', token_cache=cache)
        accounts = app.get_accounts()
        if not accounts:
            print('FAIL: MSAL cache has no accounts.', file=sys.stderr); sys.exit(1)
        result = app.acquire_token_silent(['https://database.windows.net/.default'], account=accounts[0])
        if not result or 'access_token' not in result:
            print('FAIL: MSAL token expired.', file=sys.stderr); sys.exit(1)
        tb = result['access_token'].encode('utf-16-le')
        ts = struct.pack(f'<I{len(tb)}s', len(tb), tb)
        conn = pyodbc.connect(
            f'DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};'
            'Encrypt=yes;TrustServerCertificate=no;Connection Timeout=15',
            attrs_before={1256: ts})
        method = 'MSAL token'
    cur = conn.cursor(); cur.execute('SELECT 1'); cur.fetchone(); conn.close()
    print(f'OK|{method}')
except Exception as e:
    print(f'FAIL: {e}', file=sys.stderr); sys.exit(1)
"@
    $connTestFile = Join-Path $env:TEMP "synapse_conn_test_harness.py"
    [System.IO.File]::WriteAllText($connTestFile, $connTest, [System.Text.UTF8Encoding]::new($false))
    $connResult = & python $connTestFile 2>&1
    Remove-Item $connTestFile -Force -ErrorAction SilentlyContinue

    if ($LASTEXITCODE -ne 0) {
        Write-Host "HARD FAIL: Synapse MCP connection test FAILED ($connResult)" -ForegroundColor Red
        exit 1
    }
    $authInfo = ($connResult -split '\|')[1]
    Write-Host "  Synapse connection OK ($testServer via $authInfo)" -ForegroundColor Green
    Write-Host ""
}

# ── HELPERS ──────────────────────────────────────────────────────────────────
function Find-WikiSubdir {
    # Returns "Tables", "Views", or "Functions" depending on where the SSDT
    # equivalent lives (Tables) and where any prior wiki lives. New objects
    # default to Tables/.
    param([string]$Schema, [string]$Object)
    $cand = Join-Path $repoRoot "knowledge\synapse\Wiki\$Schema\Views\$Object.md"
    if (Test-Path $cand) { return "Views" }
    $cand = Join-Path $repoRoot "knowledge\synapse\Wiki\$Schema\Functions\$Object.md"
    if (Test-Path $cand) { return "Functions" }
    return "Tables"
}

function Read-VerdictForObject {
    # The harness writes a wrapper with metadata (cost_usd, elapsed_seconds,
    # parse_error, ...) plus a nested `verdict` object that contains the
    # actual judge output: { verdict: PASS|FAIL|PARTIAL_PASS, weighted_score, ... }
    param([string]$ObjDir)
    $finalVerdict = Join-Path $ObjDir "regen\final\judge_verdict.json"
    if (-not (Test-Path $finalVerdict)) {
        return [pscustomobject]@{ Verdict = "MISSING"; Score = -1; Reason = "no judge_verdict.json in regen/final/"; CostUsd = 0 }
    }
    try {
        $j = Get-Content $finalVerdict -Raw | ConvertFrom-Json
        $cost = if ($j.PSObject.Properties.Name -contains 'cost_usd' -and $j.cost_usd) { [double]$j.cost_usd } else { 0 }
        if (-not $j.verdict_json_present -or $j.parse_error) {
            return [pscustomobject]@{
                Verdict = "PARSE_ERROR"
                Score   = -1
                Reason  = if ($j.parse_error) { $j.parse_error } else { "judge JSON missing inside output" }
                CostUsd = $cost
            }
        }
        $inner = $j.verdict
        if ($null -eq $inner) {
            return [pscustomobject]@{ Verdict = "PARSE_ERROR"; Score = -1; Reason = "no nested verdict object"; CostUsd = $cost }
        }
        $v = if ($inner.PSObject.Properties.Name -contains 'verdict') { [string]$inner.verdict } else { "UNKNOWN" }
        $s = if ($inner.PSObject.Properties.Name -contains 'weighted_score') { [double]$inner.weighted_score } else { -1 }
        $r = if ($inner.PSObject.Properties.Name -contains 'regeneration_feedback') { [string]$inner.regeneration_feedback } else { "" }
        return [pscustomobject]@{ Verdict = $v; Score = $s; Reason = $r; CostUsd = $cost }
    } catch {
        return [pscustomobject]@{ Verdict = "PARSE_ERROR"; Score = -1; Reason = "$_"; CostUsd = 0 }
    }
}

function Find-RateLimitReset {
    # Scan an object's writer / judge raw streams for the Anthropic
    # rate_limit_event JSON written DURING this object's run (i.e. file
    # mtime >= $Since). Returns either:
    #   $null                                if no rate-limit event was found
    #   [pscustomobject]@{ ResetEpoch=...; ResetDateTime=...; Type=... }
    # The `rate_limit_event` JSON looks like:
    #   {"type":"rate_limit_event","rate_limit_info":{
    #     "status":"rejected","resetsAt":1777395000,"rateLimitType":"five_hour",
    #     "overageStatus":"rejected","overageDisabledReason":"org_level_disabled"}}
    # The $Since param is essential: when re-running a previously rate-limited
    # object, stale rate_limit_event JSON from the old attempt still sits on
    # disk. Without time-scoping we'd false-positive on every retry.
    param(
        [string]   $ObjDir,
        [datetime] $Since = (Get-Date).AddDays(-365)
    )
    $streams = @()
    $streams += Get-ChildItem (Join-Path $ObjDir "regen\attempt_*\writer_raw_stream.jsonl") -ErrorAction SilentlyContinue
    $streams += Get-ChildItem (Join-Path $ObjDir "regen\attempt_*\judge_raw_stream.jsonl")  -ErrorAction SilentlyContinue
    $streams = $streams | Where-Object { $_.LastWriteTime -ge $Since }
    foreach ($f in ($streams | Sort-Object LastWriteTime -Descending)) {
        try {
            $lines = Get-Content $f.FullName -ErrorAction SilentlyContinue
        } catch { continue }
        foreach ($line in $lines) {
            if ($line -notmatch '"rate_limit_event"') { continue }
            try {
                $j = $line | ConvertFrom-Json
            } catch { continue }
            if ($j.type -ne 'rate_limit_event') { continue }
            $info = $j.rate_limit_info
            if (-not $info) { continue }
            if ($info.status -ne 'rejected') { continue }
            $resetEpoch = [int64]$info.resetsAt
            if ($resetEpoch -le 0) { continue }
            $resetDt = (Get-Date '1970-01-01Z').AddSeconds($resetEpoch).ToUniversalTime()
            return [pscustomobject]@{
                ResetEpoch    = $resetEpoch
                ResetDateTime = $resetDt
                Type          = [string]$info.rateLimitType
                Source        = $f.FullName
            }
        }
    }
    # Fallback: scan recent writer_log.md for the human-readable signature.
    $logs = Get-ChildItem (Join-Path $ObjDir "regen\attempt_*\writer_log.md") -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -ge $Since }
    foreach ($f in $logs) {
        try { $body = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue } catch { continue }
        if ($body -and $body -match "(?im)You['\u2019]ve hit your limit") {
            return [pscustomobject]@{
                ResetEpoch    = 0
                ResetDateTime = $null
                Type          = "unknown"
                Source        = $f.FullName
            }
        }
    }
    return $null
}

function Promote-RegenOutput {
    param(
        [string]$Schema, [string]$Object, [string]$ObjDir
    )
    $sub = Find-WikiSubdir -Schema $Schema -Object $Object
    $destDir = Join-Path $repoRoot "knowledge\synapse\Wiki\$Schema\$sub"
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }

    $finalDir = Join-Path $ObjDir "regen\final"
    $promoted = 0
    foreach ($suffix in @(".md", ".lineage.md", ".review-needed.md")) {
        $src  = Join-Path $finalDir "$Object$suffix"
        if (-not (Test-Path $src)) { continue }
        $dest = Join-Path $destDir "$Object$suffix"
        if (Test-Path $dest) {
            $bak = "$dest.bak"
            Copy-Item -Path $dest -Destination $bak -Force
        }
        Copy-Item -Path $src -Destination $dest -Force
        $promoted++
    }
    return @{ DestDir = $destDir; Subdir = $sub; FilesPromoted = $promoted }
}

# ── MAIN LOOP ────────────────────────────────────────────────────────────────
$iteration = 0
$objectsProcessed = 0
$objectsPromoted  = 0
$objectsFailed    = 0
$objectsSkipped   = 0
$totalCostUsd     = 0
$consecutiveZero  = 0
$loopStart = Get-Date

# Script-scoped accumulator used by the parallel fan-out to consolidate
# rate-limit sleeps. Initialised here so the first iteration's
# "$script:_pendingRateLimitSleepSec -gt 0" check is well-defined.
$script:_pendingRateLimitSleepSec = 0

while ($true) {
    if ($MaxIterations -gt 0 -and $iteration -ge $MaxIterations) {
        Write-Host "Reached -MaxIterations=$MaxIterations. Stopping." -ForegroundColor Yellow
        break
    }
    if ($MaxObjects -gt 0 -and $objectsProcessed -ge $MaxObjects) {
        Write-Host "Reached -MaxObjects=$MaxObjects. Stopping." -ForegroundColor Yellow
        break
    }

    $iteration++
    Write-Host ""
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Iteration $iteration -- picking next batch..." -ForegroundColor Green

    try {
        $batchInfo = Get-NextBatch `
            -SchemaName $SchemaName `
            -BatchSize $BatchSize `
            -RepoRoot $repoRoot `
            -AlterScopeOnly `
            -AlterScopeJson $scopeJson
    } catch {
        Write-Host "  Get-NextBatch FAILED: $_" -ForegroundColor Red
        break
    }

    if ($batchInfo.Empty) {
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Magenta
        Write-Host "  IN-SCOPE BACKLOG EMPTY -- $SchemaName" -ForegroundColor Magenta
        Write-Host "  All in-scope SSDT tables either documented or blacklisted." -ForegroundColor Magenta
        Write-Host "  Total iterations: $iteration  Objects processed: $objectsProcessed" -ForegroundColor Magenta
        Write-Host "  Promoted: $objectsPromoted  Failed: $objectsFailed  Skipped: $objectsSkipped" -ForegroundColor Magenta
        Write-Host "  Total cost: `$$([math]::Round($totalCostUsd,4)) USD" -ForegroundColor Magenta
        Write-Host "============================================================" -ForegroundColor Magenta
        break
    }

    Write-Host "  Picked $($batchInfo.Count) objects$( if ($batchInfo.HeavyCap) { ' (heavy-cap applied)' } )" -ForegroundColor Cyan
    foreach ($p in $batchInfo.Picked) {
        Write-Host "    - $($p.Name)  (priority=$($p.Priority), cols=$($p.Columns))" -ForegroundColor DarkCyan
    }

    if ($DryRun) {
        Write-Host "  DRY-RUN: skipping regen_one calls." -ForegroundColor Yellow
        $objectsProcessed += $batchInfo.Count
        if ($MaxIterations -le 0) {
            Write-Host "  (Dry-run defaults to one iteration. Use -MaxIterations N to see more.)" -ForegroundColor DarkGray
            break
        }
        continue
    }

    # ── T3: job-controlled fan-out across $Parallelism slots ────────────────
    # We fan out up to $Parallelism regen_one jobs at once. Each job runs in
    # its own PowerShell runspace (Start-Job) so claude.cmd processes truly
    # run in parallel. As each job completes we run the existing per-object
    # verdict / cost / promote / rate-limit logic. State that needed to span
    # job boundaries is stored in $jobMeta (keyed by job.Id).
    #
    # At -Parallelism 1 the fan-out degenerates to serial: at most one job
    # is in-flight at any moment, behaviour matches legacy.
    #
    # Per-object output from Start-Job is buffered until job completion and
    # then flushed via Receive-Job. We sacrifice real-time per-object stream
    # (the user sees a wall of text per object after it finishes) for actual
    # wall-clock throughput. The individual writer_log.md / judge_log.md
    # files in audits/regen-sample/ remain the authoritative live trace.

    $jobMeta = @{}            # job.Id -> @{ Object; ObjDir; ObjStart; WriterModel; Cols; Idx }
    $pendingQueue = New-Object System.Collections.Generic.Queue[object]
    foreach ($p in $batchInfo.Picked) { $pendingQueue.Enqueue($p) }
    $breakOuter = $false      # set when rate-limit is so far away we should bail
    $idx = $objectsProcessed   # 1-based display index across the whole loop

    while (($pendingQueue.Count -gt 0 -or $jobMeta.Count -gt 0) -and -not $breakOuter) {

        # ── Fan out: launch jobs up to the parallelism cap ──────────────────
        while ($jobMeta.Count -lt $Parallelism -and $pendingQueue.Count -gt 0 -and -not $breakOuter) {
            # Honour MaxObjects across the whole loop (in-flight + processed)
            if ($MaxObjects -gt 0 -and ($objectsProcessed + $jobMeta.Count) -ge $MaxObjects) { break }

            $p = $pendingQueue.Dequeue()
            $obj = $p.Name
            $objDir = Join-Path $repoRoot "audits\regen-sample\$SchemaName\$obj"
            if (-not (Test-Path $objDir)) {
                New-Item -ItemType Directory -Force -Path $objDir | Out-Null
            }

            # ── Lever 1: pick writer model based on object complexity ───────
            $cols = 0
            if ($p.PSObject.Properties.Name -contains 'Columns' -and $p.Columns) { $cols = [int]$p.Columns }
            $writerModel = if ($cols -gt 0 -and $cols -le $SimpleColThreshold) { $WriterModelSimple } else { $WriterModelComplex }

            $idx++
            $job = Start-Job -ScriptBlock {
                param($regenOne, $schema, $obj, $writerModel, $judgeModel, $writerTimeout, $judgeTimeout, $enableAutoVerify, $autoVerifyMaxCols, $enableAutoPromote, $autoPromoteMinScore)
                $regenArgs = @(
                    "-Schema", $schema, "-ObjectName", $obj,
                    "-MaxAttempts", 2,
                    "-WriterTimeoutSeconds", $writerTimeout,
                    "-JudgeTimeoutSeconds", $judgeTimeout,
                    "-WriterModel", $writerModel,
                    "-JudgeModel",  $judgeModel
                )
                if ($enableAutoVerify) {
                    $regenArgs += @("-EnableAutoVerify", "-AutoVerifyMaxCols", $autoVerifyMaxCols)
                }
                if ($enableAutoPromote) {
                    $regenArgs += @("-EnableAutoPromote", "-AutoPromoteMinScore", $autoPromoteMinScore)
                }
                & $regenOne @regenArgs
                # Emit the regen_one exit code as the LAST line so the parent
                # can pull it back via Receive-Job. Job output is purely text
                # from regen_one's Write-Host stream, none of which we parse.
                "REGEN_EXIT_CODE=$LASTEXITCODE"
            } -ArgumentList $regenOne, $SchemaName, $obj, $writerModel, $JudgeModel, $WriterTimeout, $JudgeTimeout, $EnableAutoVerify.IsPresent, $AutoVerifyMaxCols, $EnableAutoPromote.IsPresent, $AutoPromoteMinScore

            $jobMeta[$job.Id] = @{
                Object      = $obj
                ObjDir      = $objDir
                ObjStart    = Get-Date
                WriterModel = $writerModel
                Cols        = $cols
                Idx         = $idx
                Job         = $job
            }
            Write-Host ""
            Write-Host ("  >>> [$idx] $SchemaName.$obj launched (job $($job.Id), cols=$cols, writer=$writerModel, judge=$JudgeModel) -- $($jobMeta.Count)/$Parallelism slot(s) busy") -ForegroundColor Green
        }

        if ($jobMeta.Count -eq 0) { break }   # nothing in flight, queue drained

        # ── Wait for ANY job to finish ──────────────────────────────────────
        $jobObjects = $jobMeta.Values | ForEach-Object { $_.Job }
        $finishedSet = Wait-Job -Job $jobObjects -Any

        # Wait-Job -Any can return MULTIPLE jobs if several finished in the
        # same poll tick. Process each one fully.
        $finishedJobs = @($finishedSet) | Where-Object { $_.State -ne 'Running' -and $_.State -ne 'NotStarted' }
        # Also pick up any other jobs that completed while we were processing
        # the first one (Wait-Job -Any wakes on the first; siblings may have
        # finished too).
        foreach ($j in $jobObjects) {
            if ($j.State -ne 'Running' -and $j.State -ne 'NotStarted' -and ($finishedJobs -notcontains $j)) {
                $finishedJobs += $j
            }
        }

        foreach ($f in $finishedJobs) {
            if (-not $jobMeta.ContainsKey($f.Id)) { continue }
            $meta = $jobMeta[$f.Id]
            $obj      = $meta.Object
            $objDir   = $meta.ObjDir
            $objStart = $meta.ObjStart
            $cols     = $meta.Cols

            # Drain the job's buffered Write-Host output. Replay it under a
            # per-object banner so the user can attribute log lines correctly.
            $jobOutput = Receive-Job -Job $f -Keep
            $regenExit = -1
            foreach ($line in $jobOutput) {
                $s = [string]$line
                if ($s -match '^REGEN_EXIT_CODE=(-?\d+)') {
                    $regenExit = [int]$matches[1]
                } else {
                    Write-Host "    [$($meta.Idx) $obj]  $s"
                }
            }
            Remove-Job -Job $f -Force | Out-Null
            $jobMeta.Remove($f.Id) | Out-Null
            $objElapsed = [math]::Round(((Get-Date) - $objStart).TotalSeconds, 1)
            $objectsProcessed++

            # ── Verdict-gated promotion (per object, unchanged logic) ──────
            $v = Read-VerdictForObject -ObjDir $objDir
            $shouldPromote = (-not $NoPromote) -and ($PromoteVerdicts -contains $v.Verdict) -and ($regenExit -eq 0)

            $verdictColor = switch ($v.Verdict) {
                "PASS"         { "Green" }
                "PARTIAL_PASS" { "DarkYellow" }
                "FAIL"         { "Red" }
                default        { "DarkGray" }
            }
            Write-Host ("  <<< [$($meta.Idx)] $obj  Verdict: $($v.Verdict)  Score: $($v.Score)  Elapsed: ${objElapsed}s  regen_exit=$regenExit") -ForegroundColor $verdictColor

            # Per-object cost = sum of writer attempts + sum of judge attempts.
            $objCost = 0
            Get-ChildItem (Join-Path $objDir "regen\attempt_*\writer_summary.json") -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    $w = Get-Content $_.FullName -Raw | ConvertFrom-Json
                    if ($w.cost_usd) { $objCost += [double]$w.cost_usd }
                } catch { }
            }
            Get-ChildItem (Join-Path $objDir "regen\attempt_*\judge_verdict.json") -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    $j2 = Get-Content $_.FullName -Raw | ConvertFrom-Json
                    if ($j2.cost_usd) { $objCost += [double]$j2.cost_usd }
                } catch { }
            }
            $totalCostUsd += $objCost
            Write-Host ("    [$($meta.Idx)] cost: `$$([math]::Round($objCost,4)) USD  (running total: `$$([math]::Round($totalCostUsd,4)))") -ForegroundColor DarkGray

            if ($shouldPromote) {
                try {
                    $r = Promote-RegenOutput -Schema $SchemaName -Object $obj -ObjDir $objDir
                    Write-Host ("    [$($meta.Idx)] PROMOTED -> Wiki\$SchemaName\$($r.Subdir)\  ($($r.FilesPromoted) files)") -ForegroundColor Green
                    $objectsPromoted++
                } catch {
                    Write-Host ("    [$($meta.Idx)] PROMOTE FAILED: $_") -ForegroundColor Red
                    $objectsFailed++
                }
            } elseif ($v.Verdict -eq "FAIL" -or $v.Verdict -eq "MISSING" -or $v.Verdict -eq "PARSE_ERROR") {
                $objectsFailed++
                Add-Content -Path $failedLog -Value "$(Get-Date -Format 's')`t$SchemaName.$obj`tverdict=$($v.Verdict)`tscore=$($v.Score)`treason=$($v.Reason)"
                Write-Host ("    [$($meta.Idx)] Left in audits/, logged to $failedLog") -ForegroundColor Yellow
            } else {
                $objectsSkipped++
                Write-Host ("    [$($meta.Idx)] Verdict $($v.Verdict) not in -PromoteVerdicts; left in audits/ (not promoted, not failed)") -ForegroundColor DarkYellow
            }

            # ── Rate-limit watchdog (per-object, unchanged logic) ──────────
            $isZeroCostFail = ($objCost -le 0) -and ($v.Verdict -in @('MISSING','PARSE_ERROR','FAIL'))
            if ($isZeroCostFail) {
                $rlim = Find-RateLimitReset -ObjDir $objDir -Since $objStart
                if ($rlim) {
                    Write-Host ""
                    Write-Host "  RATE LIMIT DETECTED ($($rlim.Type)) on object [$($meta.Idx)] $obj" -ForegroundColor Magenta
                    if ($rlim.ResetDateTime) {
                        $now = (Get-Date).ToUniversalTime()
                        $waitSec = [int]($rlim.ResetDateTime - $now).TotalSeconds + 30
                        if ($waitSec -le 0) {
                            Write-Host ("  Reset time {0:HH:mm:ss UTC} has already passed -- retrying immediately." -f $rlim.ResetDateTime) -ForegroundColor Yellow
                            $consecutiveZero = 0
                        } elseif ($waitSec -gt 14400) {
                            Write-Host ("  Reset is {0:N1} h away (>4h) -- draining in-flight jobs then exiting. Restart after {1:HH:mm UTC}." -f ($waitSec/3600), $rlim.ResetDateTime) -ForegroundColor Red
                            Write-Host "============================================================" -ForegroundColor Red
                            $breakOuter = $true
                        } else {
                            # In parallel mode every other in-flight job is
                            # almost certainly also rate-limited (same global
                            # quota). Drain them first so we know their state,
                            # THEN sleep once for the whole batch.
                            if ($jobMeta.Count -gt 0) {
                                Write-Host ("  Draining {0} other in-flight job(s) before sleeping (they're likely also rate-limited)..." -f $jobMeta.Count) -ForegroundColor Yellow
                            }
                            # Sleep gets re-evaluated after draining so the
                            # batched sleep happens once at the end.
                            $script:_pendingRateLimitSleepSec = [Math]::Max($script:_pendingRateLimitSleepSec, $waitSec)
                        }
                    } else {
                        Write-Host "  Rate-limit hit but no reset epoch found in stream. Will sleep 30 min after batch drains." -ForegroundColor Yellow
                        $script:_pendingRateLimitSleepSec = [Math]::Max($script:_pendingRateLimitSleepSec, 1800)
                    }
                } else {
                    $consecutiveZero++
                    if ($consecutiveZero -ge 3) {
                        Write-Host ""
                        Write-Host "  3 consecutive zero-cost failures with no rate-limit signal. Likely auth / MCP / writer-prompt issue. EXITING to prevent wasted iterations." -ForegroundColor Red
                        Write-Host "  Inspect: $failedLog" -ForegroundColor Red
                        Write-Host "============================================================" -ForegroundColor Red
                        $breakOuter = $true
                    }
                }
            } else {
                $consecutiveZero = 0
            }

            if ($MaxObjects -gt 0 -and $objectsProcessed -ge $MaxObjects) {
                Write-Host "  Reached -MaxObjects=$MaxObjects (drained all current in-flight jobs). Stopping after batch." -ForegroundColor Yellow
                # We allow the inner foreach to continue draining the rest of
                # the finished jobs so we don't lose their verdict/promote
                # state, but we set $breakOuter so no NEW jobs get started.
                $breakOuter = $true
            }
        }

        # ── Batched rate-limit sleep ────────────────────────────────────────
        # If any of the just-completed jobs detected a rate-limit and ALL
        # in-flight jobs have now drained, perform a single consolidated sleep
        # so we don't multiply per-object sleeps in parallel mode.
        if ($script:_pendingRateLimitSleepSec -gt 0 -and $jobMeta.Count -eq 0 -and -not $breakOuter) {
            $waitSec = $script:_pendingRateLimitSleepSec
            $script:_pendingRateLimitSleepSec = 0
            $resetAt = (Get-Date).AddSeconds($waitSec)
            Write-Host ("  Sleeping {0:N1} min (consolidated rate-limit) until ~{1:HH:mm:ss}..." -f ($waitSec/60), $resetAt) -ForegroundColor Yellow
            Start-Sleep -Seconds $waitSec
            Write-Host "  Resuming after rate-limit sleep." -ForegroundColor Green
            $consecutiveZero = 0
        }
    }

    # Reset the per-batch rate-limit accumulator for the next iteration.
    $script:_pendingRateLimitSleepSec = 0

    # If the inner loop set $breakOuter (rate-limit reset >4h, three
    # consecutive zero-cost failures, or MaxObjects reached), bail the outer
    # while-true.
    if ($breakOuter) { break }

    Write-Host ""
    Write-Host "  -- Iteration $iteration complete -- $objectsProcessed processed, $objectsPromoted promoted, $objectsFailed failed, $objectsSkipped skipped, total cost `$$([math]::Round($totalCostUsd,4))" -ForegroundColor Yellow
}

$loopElapsed = [math]::Round(((Get-Date) - $loopStart).TotalMinutes, 1)
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Loop summary  (elapsed: ${loopElapsed} min)" -ForegroundColor Cyan
Write-Host "  Iterations:        $iteration" -ForegroundColor Cyan
Write-Host "  Objects processed: $objectsProcessed" -ForegroundColor Cyan
Write-Host "  Promoted to wiki:  $objectsPromoted" -ForegroundColor Cyan
Write-Host "  Failed (in audits): $objectsFailed" -ForegroundColor Cyan
Write-Host "  Skipped:           $objectsSkipped" -ForegroundColor Cyan
Write-Host "  Total cost:        `$$([math]::Round($totalCostUsd,4)) USD" -ForegroundColor Cyan
if ($objectsFailed -gt 0) {
    Write-Host "  Failure log:       $failedLog" -ForegroundColor Yellow
}
Write-Host "============================================================" -ForegroundColor Cyan
