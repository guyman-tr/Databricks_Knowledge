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

    # ── Live-write behaviour ────────────────────────────────────────────────
    # regen_one.ps1 ALWAYS writes the best attempt directly into
    # knowledge/synapse/Wiki/{Schema}/{Tables|Views|Functions}/. Pass
    # -NoLiveWrite to keep the regen output in audits/regen-sample/ only.
    # Existing live files are backed up to <name>.bak before overwrite.
    [Parameter(Mandatory=$false)] [switch]   $NoLiveWrite
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
Write-Host "  Mode:     serial (one regen_one at a time, claude.cmd default model)" -ForegroundColor Cyan
Write-Host ("  LiveWrite: {0}" -f $(if ($NoLiveWrite) { "OFF (-NoLiveWrite set; output stays in audits/regen-sample/)" } else { "ON (best attempt written directly into knowledge/synapse/Wiki/, .bak written if file existed)" })) -ForegroundColor Cyan
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

    # ── Serial inner loop: one regen_one.ps1 at a time, inline ──────────────
    # No parallelism, no Start-Job, no model routing. Each object inherits
    # claude.cmd's default model (Opus). regen_one streams Write-Host directly
    # to this terminal, so the user sees per-object progress live.
    $breakOuter = $false
    $idx = $objectsProcessed

    foreach ($p in $batchInfo.Picked) {
        if ($breakOuter) { break }
        if ($MaxObjects -gt 0 -and $objectsProcessed -ge $MaxObjects) {
            Write-Host "  Reached -MaxObjects=$MaxObjects. Stopping." -ForegroundColor Yellow
            $breakOuter = $true
            break
        }

        $obj = $p.Name
        $objDir = Join-Path $repoRoot "audits\regen-sample\$SchemaName\$obj"
        if (-not (Test-Path $objDir)) {
            New-Item -ItemType Directory -Force -Path $objDir | Out-Null
        }
        $cols = 0
        if ($p.PSObject.Properties.Name -contains 'Columns' -and $p.Columns) { $cols = [int]$p.Columns }
        $idx++
        $objStart = Get-Date

        Write-Host ""
        Write-Host ("  >>> [$idx] $SchemaName.$obj  (cols=$cols)") -ForegroundColor Green

        $regenSplat = @{
            Schema               = $SchemaName
            ObjectName           = $obj
            MaxAttempts          = 2
            WriterTimeoutSeconds = $WriterTimeout
            JudgeTimeoutSeconds  = $JudgeTimeout
        }
        if ($NoLiveWrite) { $regenSplat['NoLiveWrite'] = $true }

        & $regenOne @regenSplat
        $regenExit = $LASTEXITCODE
        $objElapsed = [math]::Round(((Get-Date) - $objStart).TotalSeconds, 1)
        $objectsProcessed++

        # ── Verdict-gated promotion ─────────────────────────────────────────
        $v = Read-VerdictForObject -ObjDir $objDir
        $shouldPromote = (-not $NoPromote) -and ($PromoteVerdicts -contains $v.Verdict) -and ($regenExit -eq 0)

        $verdictColor = switch ($v.Verdict) {
            "PASS"         { "Green" }
            "PARTIAL_PASS" { "DarkYellow" }
            "FAIL"         { "Red" }
            default        { "DarkGray" }
        }
        Write-Host ("  <<< [$idx] $obj  Verdict: $($v.Verdict)  Score: $($v.Score)  Elapsed: ${objElapsed}s  regen_exit=$regenExit") -ForegroundColor $verdictColor

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
        Write-Host ("    [$idx] cost: `$$([math]::Round($objCost,4)) USD  (running total: `$$([math]::Round($totalCostUsd,4)))") -ForegroundColor DarkGray

        if ($shouldPromote) {
            try {
                $r = Promote-RegenOutput -Schema $SchemaName -Object $obj -ObjDir $objDir
                Write-Host ("    [$idx] PROMOTED -> Wiki\$SchemaName\$($r.Subdir)\  ($($r.FilesPromoted) files)") -ForegroundColor Green
                $objectsPromoted++
            } catch {
                Write-Host ("    [$idx] PROMOTE FAILED: $_") -ForegroundColor Red
                $objectsFailed++
            }
        } elseif ($v.Verdict -eq "FAIL" -or $v.Verdict -eq "MISSING" -or $v.Verdict -eq "PARSE_ERROR") {
            $objectsFailed++
            Add-Content -Path $failedLog -Value "$(Get-Date -Format 's')`t$SchemaName.$obj`tverdict=$($v.Verdict)`tscore=$($v.Score)`treason=$($v.Reason)"
            Write-Host ("    [$idx] Left in audits/, logged to $failedLog") -ForegroundColor Yellow
        } else {
            $objectsSkipped++
            Write-Host ("    [$idx] Verdict $($v.Verdict) not in -PromoteVerdicts; left in audits/ (not promoted, not failed)") -ForegroundColor DarkYellow
        }

        # ── Rate-limit watchdog (per-object) ───────────────────────────────
        $isZeroCostFail = ($objCost -le 0) -and ($v.Verdict -in @('MISSING','PARSE_ERROR','FAIL'))
        if ($isZeroCostFail) {
            $rlim = Find-RateLimitReset -ObjDir $objDir -Since $objStart
            if ($rlim) {
                Write-Host ""
                Write-Host "  RATE LIMIT DETECTED ($($rlim.Type)) on object [$idx] $obj" -ForegroundColor Magenta
                if ($rlim.ResetDateTime) {
                    $now = (Get-Date).ToUniversalTime()
                    $waitSec = [int]($rlim.ResetDateTime - $now).TotalSeconds + 30
                    if ($waitSec -le 0) {
                        Write-Host ("  Reset time {0:HH:mm:ss UTC} has already passed -- retrying immediately." -f $rlim.ResetDateTime) -ForegroundColor Yellow
                        $consecutiveZero = 0
                    } elseif ($waitSec -gt 14400) {
                        Write-Host ("  Reset is {0:N1} h away (>4h) -- exiting. Restart after {1:HH:mm UTC}." -f ($waitSec/3600), $rlim.ResetDateTime) -ForegroundColor Red
                        Write-Host "============================================================" -ForegroundColor Red
                        $breakOuter = $true
                    } else {
                        $resetAt = (Get-Date).AddSeconds($waitSec)
                        Write-Host ("  Sleeping {0:N1} min (rate-limit) until ~{1:HH:mm:ss}..." -f ($waitSec/60), $resetAt) -ForegroundColor Yellow
                        Start-Sleep -Seconds $waitSec
                        Write-Host "  Resuming after rate-limit sleep." -ForegroundColor Green
                        $consecutiveZero = 0
                    }
                } else {
                    Write-Host "  Rate-limit hit but no reset epoch in stream. Sleeping 30 min." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1800
                    Write-Host "  Resuming after rate-limit sleep." -ForegroundColor Green
                    $consecutiveZero = 0
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
    }

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
