param(
    [string]$SchemaName = "",
    [string]$DocLevel = ""
)

$ErrorActionPreference = 'Continue'

if (-not $SchemaName) {
    $SchemaName = Read-Host "Schema Name (default: DWH_dbo)"
    if (-not $SchemaName) { $SchemaName = "DWH_dbo" }
}

$claudePath = "$env:APPDATA\npm\claude.cmd"
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$indexPath = Join-Path $repoRoot "knowledge\synapse\Wiki\$SchemaName\_index.md"

# Resolve prompt file and inject schema name
if ($SchemaName -eq "BI_DB_dbo") {
    $basePromptFile = Join-Path $repoRoot ".claude\prompts\build-wiki-bidb-batch.md"
} else {
    $basePromptFile = Join-Path $repoRoot ".claude\prompts\build-wiki-dwh-batch.md"
}
# Per-iteration prompt files use the iteration number to guarantee a fresh path
# every time, so a leaked file handle on a previous iteration's prompt cannot
# block the next write. The path is set inside the loop; below is the pattern
# used for display only.
$promptFilePattern = Join-Path $env:TEMP ("claude_wiki_prompt_{0}_<iter>.md" -f $SchemaName)

# Per-schema default batch size (heavy weighted exception applied inside Get-NextBatch).
$schemaBatchSize = switch ($SchemaName) {
    "BI_DB_dbo"   { 8 }
    "DWH_dbo"     { 4 }
    "Dealing_dbo" { 4 }
    "eMoney_dbo"  { 6 }
    "EXW_dbo"     { 6 }
    default       { 4 }
}

# Dot-source the shared batch picker (Workstream 1c).
$libPath = Join-Path $PSScriptRoot "lib\Get-NextBatch.ps1"
if (Test-Path $libPath) {
    . $libPath
    $usePrePicker = $true
} else {
    Write-Host "WARN: Get-NextBatch.ps1 not found at $libPath - falling back to in-prompt discovery." -ForegroundColor Yellow
    $usePrePicker = $false
}

# Dot-source the quality drift guard (Workstream 1d). Kicks in once the loop
# has produced a baseline of completed batches; throttles batch size on mild
# drift, kills the loop on severe drift to prevent burning tokens on garbage.
$driftPath = Join-Path $PSScriptRoot "lib\Test-QualityDrift.ps1"
if (Test-Path $driftPath) {
    . $driftPath
    $useDriftGuard = $true
} else {
    Write-Host "WARN: Test-QualityDrift.ps1 not found at $driftPath - drift guard disabled." -ForegroundColor Yellow
    $useDriftGuard = $false
}

# Dot-source the Patch 1.5 compliance check. Catches the 2026-04-27 failure
# mode where the agent's lineage correctly identifies passthrough rows from
# documented Synapse dims but the wiki tags them Tier 2 instead of Tier 1
# AND skips the UPSTREAM SEARCH LOG self-check. Hard violations are written
# to audits/patch15-must-fix.txt for the post-run wiki auditor to re-grade.
$patchCheckPath = Join-Path $PSScriptRoot "lib\Test-Patch15Compliance.ps1"
if (Test-Path $patchCheckPath) {
    . $patchCheckPath
    $usePatch15Check = $true
} else {
    Write-Host "WARN: Test-Patch15Compliance.ps1 not found at $patchCheckPath - Patch 1.5 guardrail disabled." -ForegroundColor Yellow
    $usePatch15Check = $false
}

if (-not (Test-Path $claudePath)) {
    Write-Host "ERROR: claude not found at $claudePath" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $basePromptFile)) {
    Write-Host "ERROR: prompt file not found at $basePromptFile" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Wiki Batch Loop (wiki-only - no ALTER generation)" -ForegroundColor Cyan
Write-Host "  Schema:  $SchemaName" -ForegroundColor Cyan
Write-Host "  Prompts: $promptFilePattern" -ForegroundColor Cyan
if ($DocLevel) {
    Write-Host "  Filter:  $DocLevel" -ForegroundColor Cyan
}
Write-Host "  Repo:    $repoRoot" -ForegroundColor Cyan
Write-Host "  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
# ── PRE-FLIGHT: Synapse MCP connection health check ──────────────────────────
# The wiki pipeline REQUIRES live Synapse access for Phase 2 (sampling) and
# Phase 3 (distribution). Without it, wikis are code-only and lack data evidence.
# This is a HARD gate — the loop refuses to start if Synapse is unreachable.
Write-Host "Pre-flight: testing Synapse MCP connection..." -ForegroundColor Yellow

$mcpJson = Join-Path $env:USERPROFILE ".cursor\mcp.json"
if (-not (Test-Path $mcpJson)) {
    $mcpJson = Join-Path $repoRoot ".mcp.json"
}
if (-not (Test-Path $mcpJson)) {
    Write-Host "HARD FAIL: mcp.json not found at ~/.cursor/mcp.json or $repoRoot\.mcp.json" -ForegroundColor Red
    Write-Host "Cannot start wiki loop without MCP configuration." -ForegroundColor Red
    exit 1
}

$mcpServerScript = "C:\Users\guyman\.cursor\synapse-mcp-server.py"
if (-not (Test-Path $mcpServerScript)) {
    Write-Host "HARD FAIL: synapse-mcp-server.py not found." -ForegroundColor Red
    exit 1
}

$mcpConfig = Get-Content $mcpJson -Raw | ConvertFrom-Json
$synEnv = $mcpConfig.mcpServers.synapse_sql.env
$testServer = if ($synEnv.SYNAPSE_SERVER) { $synEnv.SYNAPSE_SERVER } else { "stg-synapse-dataplatform-we.sql.azuresynapse.net" }
$testDb     = if ($synEnv.SYNAPSE_DATABASE) { $synEnv.SYNAPSE_DATABASE } else { "sql_dp_stg_we_BI_no_retention" }

# Pre-flight uses the SAME auth logic as the MCP server: env vars > .env file > MSAL token
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
            timeout=15
        )
        method = f'SQL auth ({sql_user})'
    else:
        import struct, msal
        cache_path = os.path.join(os.environ.get('LOCALAPPDATA', os.path.expanduser('~')), 'synapse-mcp-token-cache.bin')
        if not os.path.exists(cache_path):
            print('FAIL: No SQL creds and no MSAL token cache.', file=sys.stderr)
            sys.exit(1)
        cache = msal.SerializableTokenCache()
        cache.deserialize(open(cache_path).read())
        app = msal.PublicClientApplication('1950a258-227b-4e31-a9cf-717495945fc2',
              authority='https://login.microsoftonline.com/organizations', token_cache=cache)
        accounts = app.get_accounts()
        if not accounts:
            print('FAIL: MSAL cache has no accounts.', file=sys.stderr)
            sys.exit(1)
        result = app.acquire_token_silent(['https://database.windows.net/.default'], account=accounts[0])
        if not result or 'access_token' not in result:
            print('FAIL: MSAL token expired.', file=sys.stderr)
            sys.exit(1)
        tb = result['access_token'].encode('utf-16-le')
        ts = struct.pack(f'<I{len(tb)}s', len(tb), tb)
        conn = pyodbc.connect(
            f'DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};'
            'Encrypt=yes;TrustServerCertificate=no;Connection Timeout=15',
            attrs_before={1256: ts}
        )
        method = 'MSAL token'
    cur = conn.cursor()
    cur.execute('SELECT 1')
    cur.fetchone()
    conn.close()
    print(f'OK|{method}')
except Exception as e:
    print(f'FAIL: {e}', file=sys.stderr)
    sys.exit(1)
"@

$connTestFile = Join-Path $env:TEMP "synapse_conn_test.py"
[System.IO.File]::WriteAllText($connTestFile, $connTest, [System.Text.UTF8Encoding]::new($false))
$connResult = & python $connTestFile 2>&1
Remove-Item $connTestFile -Force -ErrorAction SilentlyContinue

if ($LASTEXITCODE -ne 0) {
    Write-Host "" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "  HARD FAIL: Synapse MCP connection test FAILED" -ForegroundColor Red
    Write-Host "  Server: $testServer" -ForegroundColor Red
    Write-Host "  Error:  $connResult" -ForegroundColor Red
    Write-Host "" -ForegroundColor Red
    Write-Host "  The wiki pipeline REQUIRES live Synapse access for Phase 2" -ForegroundColor Red
    Write-Host "  (data sampling) and Phase 3 (distribution analysis)." -ForegroundColor Red
    Write-Host "  Fix credentials in synapse-credentials.env or .mcp.json" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    exit 1
}

$authInfo = ($connResult -split '\|')[1]
Write-Host "  Synapse connection OK ($testServer via $authInfo)" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop between iterations." -ForegroundColor Gray
Write-Host ""

# ── STARTUP SWEEP: clear stale temp files from previous runs ─────────────────
# A leaked file handle on $env:TEMP\claude_wiki_prompt_<schema>.md from a hung
# claude.exe (or its parent shell) can poison subsequent runs even after the
# process is killed, because Windows takes time to release the handle and the
# old static-path scheme tried to overwrite the same locked path forever.
# Per-iteration filenames (set inside the loop) prevent this going forward,
# but we still proactively delete anything older than 1 hour at startup.
$staleAge = New-TimeSpan -Hours 1
$stalePatterns = @("claude_wiki_prompt_*.md", "claude_wiki_batch_*.jsonl", "claude_wiki_batch_err_*.tmp")
$sweptCount = 0
$lockedCount = 0
foreach ($pat in $stalePatterns) {
    Get-ChildItem (Join-Path $env:TEMP $pat) -ErrorAction SilentlyContinue |
      Where-Object { ((Get-Date) - $_.LastWriteTime) -gt $staleAge } |
      ForEach-Object {
          try   { Remove-Item $_.FullName -Force -ErrorAction Stop; $sweptCount++ }
          catch { $lockedCount++ }
      }
}
if (($sweptCount + $lockedCount) -gt 0) {
    Write-Host "Startup sweep: removed $sweptCount stale temp files; $lockedCount still locked (will be skipped — per-iteration filenames avoid them)." -ForegroundColor DarkGray
}

$iteration = 1
$totalCostUsd = 0
$consecutiveZeroIterations = 0
# $effectiveBatchSize is the size used for the NEXT iteration. Starts at the
# schema default; the drift guard may temporarily lower it after each iteration.
$effectiveBatchSize = $schemaBatchSize

while ($true) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Iteration $iteration started..." -ForegroundColor Green
    Write-Host ""

    # Capture the wall-clock start of this iteration so the Patch 1.5 guardrail
    # can scope its scan to wikis that were actually written by THIS iteration
    # (not pre-existing files that happen to be flawed).
    $iterationStart = Get-Date

    # ---- Build per-iteration prompt -----------------------------------------
    # Base prompt + schema scope footer + (optional) BATCH ASSIGNMENT block from picker.
    $basePromptContent = Get-Content $basePromptFile -Raw
    $schemaScopeFooter = "`n`n## Schema argument`n`nSchema: $SchemaName`n`nProcess ONLY objects from the $SchemaName schema. Do NOT document objects from other schemas, even if they appear as cross-schema dependencies. Cross-schema dependencies are treated as Tier 4 (best available knowledge) - read their data if available but do NOT create wiki files for them.`n"
    $batchBlock = ""
    if ($usePrePicker) {
        try {
            if ($effectiveBatchSize -ne $schemaBatchSize) {
                Write-Host "  [DRIFT GUARD] Using throttled batch size: $effectiveBatchSize (schema default: $schemaBatchSize)." -ForegroundColor Yellow
            }
            $batchInfo = Get-NextBatch -SchemaName $SchemaName -BatchSize $effectiveBatchSize -RepoRoot $repoRoot
            if ($batchInfo.Empty) {
                Write-Host ""
                Write-Host "============================================================" -ForegroundColor Magenta
                Write-Host "  PRE-PICKER: No pending objects in $SchemaName" -ForegroundColor Magenta
                Write-Host "  All SSDT tables either documented or blacklisted." -ForegroundColor Magenta
                Write-Host "  Total cost: `$$([math]::Round($totalCostUsd, 4)) USD" -ForegroundColor Magenta
                Write-Host "============================================================" -ForegroundColor Magenta
                break
            }
            $batchBlock = $batchInfo.Block
            Write-Host "  Pre-picker selected $($batchInfo.Count) objects (HeavyCap=$($batchInfo.HeavyCap))." -ForegroundColor Cyan
        } catch {
            Write-Host "  WARN: Pre-picker failed: $_ - falling back to in-prompt discovery." -ForegroundColor Yellow
            $batchBlock = ""
        }
    }
    $promptContent = $basePromptContent + $schemaScopeFooter + $batchBlock
    # Unique-per-iteration prompt file — prevents file-lock issues if a previous
    # iteration's claude.exe (or shell) leaked a handle on the path.
    $promptFile = Join-Path $env:TEMP ("claude_wiki_prompt_{0}_{1}.md" -f $SchemaName, $iteration)
    [System.IO.File]::WriteAllText($promptFile, $promptContent, [System.Text.UTF8Encoding]::new($false))

    $inputTokens = 0
    $outputTokens = 0
    $costUsd = 0

    $batchMaxSeconds = 3000  # 50 min ceiling — accommodates batch size 8 (was 1800/30min for batch size 4)
    $postResultGrace = 30    # kill 30s after "result" event (conversation done but process lingers)

    $tempOut = Join-Path $env:TEMP "claude_wiki_batch_$iteration.jsonl"
    $tempErr = Join-Path $env:TEMP "claude_wiki_batch_err_$iteration.tmp"
    Remove-Item $tempOut -Force -ErrorAction SilentlyContinue
    Remove-Item $tempErr -Force -ErrorAction SilentlyContinue

    try {
        $proc = Start-Process -FilePath $claudePath `
            -ArgumentList "--dangerously-skip-permissions --verbose --output-format stream-json --print" `
            -WorkingDirectory $repoRoot `
            -PassThru -NoNewWindow `
            -RedirectStandardInput $promptFile `
            -RedirectStandardOutput $tempOut `
            -RedirectStandardError $tempErr

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $lastSize = 0
        $gotResult = $false
        $resultElapsed = 0

        while (-not $proc.HasExited) {
            Start-Sleep -Milliseconds 500

            if ($gotResult -and ($sw.Elapsed.TotalSeconds - $resultElapsed) -gt $postResultGrace) {
                Write-Host "`n  Post-result cleanup: process did not exit within $($postResultGrace)s -- killing." -ForegroundColor DarkYellow
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                break
            }
            if ($sw.Elapsed.TotalSeconds -gt $batchMaxSeconds) {
                Write-Host "`n  TIMEOUT ($($batchMaxSeconds)s): Killing hung Claude process..." -ForegroundColor Red
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                break
            }

            if (-not (Test-Path $tempOut)) { continue }
            $fi = Get-Item $tempOut -ErrorAction SilentlyContinue
            if ($null -eq $fi -or $fi.Length -le $lastSize) { continue }

            try {
                $stream = [System.IO.File]::Open($tempOut, 'Open', 'Read', 'ReadWrite')
                $stream.Seek($lastSize, 'Begin') | Out-Null
                $reader = New-Object System.IO.StreamReader($stream)
                while ($null -ne ($line = $reader.ReadLine())) {
                    try {
                        $obj = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
                        if ($null -eq $obj) { continue }
                        if ($obj.type -eq "assistant" -and $obj.message.content) {
                            foreach ($block in $obj.message.content) {
                                if ($block.type -eq "text" -and $block.text) {
                                    $txt = $block.text
                                    # Show key progress lines in full, suppress verbose noise
                                    if ($txt -match "COMPLETE|BATCH|PHASE.*CHECKPOINT|Object \d+/\d+|PASS|FAIL|HARD STOP|Schema:") {
                                        Write-Host $txt -NoNewline
                                    }
                                    elseif ($txt -match "Phase \d+|Adversarial|Evaluator|Weighted Total|Dim \d") {
                                        Write-Host $txt -NoNewline -ForegroundColor DarkGray
                                    }
                                    else {
                                        # Print first 120 chars of other text to show activity
                                        $short = if ($txt.Length -gt 120) { $txt.Substring(0,120) + "..." } else { $txt }
                                        $short = $short -replace "`n", " "
                                        if ($short.Trim().Length -gt 0) {
                                            Write-Host "  $short" -ForegroundColor DarkGray
                                        }
                                    }
                                } elseif ($block.type -eq "tool_use") {
                                    $toolName = $block.name
                                    $elapsed = [math]::Round($sw.Elapsed.TotalSeconds)
                                    # Show file writes prominently (wiki output)
                                    if ($block.input -and $block.input.file_path -and $toolName -eq "Write") {
                                        $fp = $block.input.file_path -replace '.*Wiki\\', ''
                                        Write-Host "  [$($elapsed)s] Write: $fp" -ForegroundColor Green
                                    }
                                    elseif ($block.input -and $block.input.path -and $toolName -eq "Read") {
                                        $fp = $block.input.path -replace '.*\\', ''
                                        Write-Host "  [$($elapsed)s] Read: $fp" -ForegroundColor DarkCyan -NoNewline
                                        Write-Host ""
                                    }
                                    else {
                                        Write-Host "  [$($elapsed)s] $toolName" -ForegroundColor DarkCyan -NoNewline
                                        Write-Host ""
                                    }
                                }
                            }
                        }
                        if ($obj.type -eq "result") {
                            $gotResult = $true
                            $resultElapsed = $sw.Elapsed.TotalSeconds
                            if ($obj.usage) {
                                $inputTokens  = $obj.usage.input_tokens
                                $outputTokens = $obj.usage.output_tokens
                            }
                            if ($obj.cost_usd) { $costUsd = $obj.cost_usd }
                        }
                    } catch { }
                }
                $lastSize = $stream.Position
                $reader.Close()
                $stream.Close()
            } catch { }
        }
    } catch {
        Write-Host ""
        Write-Host "  Claude Code process error: $_" -ForegroundColor Red
    } finally {
        if ($proc -and -not $proc.HasExited) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
        # Pre-deletion scan: capture rate-limit signature from stdout before file is removed.
        $rateLimitFromStdout = $null
        if (Test-Path $tempOut) {
            try {
                $stdoutRaw = Get-Content $tempOut -Raw -ErrorAction SilentlyContinue
                if ($stdoutRaw -and $stdoutRaw -match "(You['\u2019]ve hit your limit|usage limit reached)") {
                    $rateLimitFromStdout = $stdoutRaw
                }
            } catch { }
        }
        Remove-Item $tempOut -Force -ErrorAction SilentlyContinue
        # Keep stderr for MCP debugging: $tempErr
        # Remove-Item $tempErr -Force -ErrorAction SilentlyContinue
        # Best-effort cleanup of this iteration's prompt file. If the OS still
        # holds a stale handle (e.g. claude.exe is being torn down), the next
        # iteration writes to a different filename anyway, so this is safe to
        # silently skip.
        Remove-Item $promptFile -Force -ErrorAction SilentlyContinue
    }

    $totalCostUsd += $costUsd

    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    Write-Host "  Iteration $iteration complete" -ForegroundColor Yellow
    Write-Host "    Input  : $inputTokens tokens" -ForegroundColor Yellow
    Write-Host "    Output : $outputTokens tokens" -ForegroundColor Yellow
    Write-Host "    Cost   : `$$([math]::Round($costUsd, 4)) USD" -ForegroundColor Yellow
    Write-Host "    Total  : `$$([math]::Round($totalCostUsd, 4)) USD" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow

    # Wiki-only mode: parity check is skipped (no .alter.sql files generated).
    # Parity is enforced later by the ALTER generation loop (run-dwh-alter-batch-loop.ps1).
    Write-Host "  Wiki-only mode - parity check skipped (no ALTER files)." -ForegroundColor DarkGray

    # ---- Drift guard ---------------------------------------------------------
    # Run AFTER each productive iteration to evaluate the just-completed batch.
    # The guard reads the canonical _index.md (post-write) and compares the
    # most recent batch's quality scores against the rolling baseline. It can:
    #   * leave $effectiveBatchSize at the schema default (no drift)
    #   * lower $effectiveBatchSize for the next iteration (mild drift -> throttle)
    #   * exit the loop entirely (severe drift OR consecutive drift kill switch)
    if ($useDriftGuard -and $inputTokens -gt 0) {
        try {
            $drift = Test-QualityDrift `
                -SchemaName $SchemaName `
                -RepoRoot $repoRoot `
                -DefaultBatchSize $schemaBatchSize `
                -ThrottledBatchSize 4

            $color = switch ($drift.DriftLevel) {
                "severe" { "Red" }
                "mild"   { "Yellow" }
                default  { "DarkGreen" }
            }
            Write-Host ""
            Write-Host "  [DRIFT GUARD] Batch $($drift.LastBatchNumber) -- $($drift.DriftLevel.ToUpper())" -ForegroundColor $color
            if ($drift.LastBatchAvg -ge 0) {
                Write-Host ("    Recent avg     : {0} (min {1}, n={2})" -f $drift.LastBatchAvg, $drift.LastBatchMin, $drift.LastBatchScores.Count) -ForegroundColor $color
            }
            if ($drift.BaselineMedian -ge 0) {
                Write-Host ("    Baseline median: {0} (n={1})" -f $drift.BaselineMedian, $drift.BaselineSampleN) -ForegroundColor $color
            }
            Write-Host "    Decision       : $($drift.Reason)" -ForegroundColor $color

            $effectiveBatchSize = $drift.NextBatchSize

            if ($drift.ShouldKill) {
                Write-Host ""
                Write-Host "============================================================" -ForegroundColor Red
                Write-Host "  KILL SWITCH (drift guard) -- $($drift.Reason)" -ForegroundColor Red
                Write-Host "  See state log: $repoRoot\.claude\state\quality_drift_history_$SchemaName.jsonl" -ForegroundColor Red
                Write-Host "  Restart manually after investigating recent wiki output." -ForegroundColor Red
                Write-Host "============================================================" -ForegroundColor Red
                exit 4
            }
        } catch {
            Write-Host "  WARN: Drift guard failed: $_ -- continuing at default batch size." -ForegroundColor Yellow
            $effectiveBatchSize = $schemaBatchSize
        }
    }

    # ---- Patch 1.5 compliance check -----------------------------------------
    # Detect the dim-lookup-passthrough mis-tagging fingerprint:
    #   * .lineage.md correctly says "passthrough" from Dim_X
    #   * Dim_X.md exists in this repo (so Tier 1 inheritance is feasible)
    #   * .md tags every such column Tier 2 anyway
    #   * UPSTREAM SEARCH LOG self-check block is missing
    # Wikis that match this pattern are appended to audits/patch15-must-fix.txt
    # so the post-run auditor can re-grade them once the big run finishes.
    # We do NOT kill the loop on hits -- the rest of the wiki may still be
    # useful, and re-running mid-batch wastes tokens. The auditor handles fixes.
    if ($usePatch15Check -and $inputTokens -gt 0) {
        try {
            $p15 = Test-Patch15Compliance -SchemaName $SchemaName -Since $iterationStart -RepoRoot $repoRoot
            $hard = @($p15 | Where-Object IsViolation)
            $soft = @($p15 | Where-Object { -not $_.IsViolation })
            if ($p15.Count -gt 0) {
                $color = if ($hard.Count -gt 0) { "Red" } else { "Yellow" }
                Write-Host ""
                Write-Host ("  [PATCH 1.5 GUARDRAIL] {0} hard, {1} soft signals in this iteration" -f $hard.Count, $soft.Count) -ForegroundColor $color
                foreach ($h in $hard) {
                    Write-Host ("    HARD: {0} ({1})" -f $h.Object, $h.Reason) -ForegroundColor $color
                }
                foreach ($s in $soft) {
                    Write-Host ("    soft: {0} ({1})" -f $s.Object, $s.Reason) -ForegroundColor DarkYellow
                }
                $added = Add-Patch15MustFix -Findings $p15 -RepoRoot $repoRoot
                if ($added -gt 0) {
                    Write-Host ("    Appended {0} object(s) to audits\patch15-must-fix.txt" -f $added) -ForegroundColor $color
                }
            } else {
                Write-Host "  [PATCH 1.5 GUARDRAIL] No violations in this iteration." -ForegroundColor DarkGreen
            }
        } catch {
            Write-Host "  WARN: Patch 1.5 guardrail failed: $_ -- continuing." -ForegroundColor Yellow
        }
    }

    $schemaComplete = $false
    if (Test-Path $indexPath) {
        $content = Get-Content $indexPath -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $hasPending = ($content -match "Pending") -or ($content -match "Queued")
            $pendingCount = if ($content -match 'pending:\s*(\d+)') { [int]$Matches[1] } else { -1 }
            if (-not $hasPending -and $pendingCount -eq 0) {
                $schemaComplete = $true
            }
            elseif (-not $hasPending -and $pendingCount -eq -1) {
                Write-Host "  WARNING: No 'Pending' text found in index but no 'pending: 0' either." -ForegroundColor Yellow
                Write-Host "  Index may be old-format (batch history only). Continuing loop." -ForegroundColor Yellow
            }
        }
    }

    if ($schemaComplete) {
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Magenta
        Write-Host "  SCHEMA COMPLETE - $SchemaName" -ForegroundColor Magenta
        Write-Host "  Total iterations: $iteration" -ForegroundColor Magenta
        Write-Host "  Total cost: `$$([math]::Round($totalCostUsd, 4)) USD" -ForegroundColor Magenta
        Write-Host "============================================================" -ForegroundColor Magenta
        break
    }

    if ($inputTokens -eq 0 -and $costUsd -eq 0) {
        $consecutiveZeroIterations++
        Write-Host ""
        Write-Host "  WARNING: No tokens used - iteration may have failed (consecutive: $consecutiveZeroIterations)." -ForegroundColor Red

        # Scan captured stdout (pre-delete) and stderr for the Anthropic rate-limit signature.
        $rateLimitHit = $false
        $resetText = $null
        $scanSources = @()
        if ($rateLimitFromStdout) { $scanSources += $rateLimitFromStdout }
        if (Test-Path $tempErr) {
            $errContent = Get-Content $tempErr -Raw -ErrorAction SilentlyContinue
            if ($errContent) { $scanSources += $errContent }
        }
        foreach ($scanContent in $scanSources) {
            if ($scanContent -match "(You['\u2019]ve hit your limit|usage limit reached|rate.?limit)") {
                $rateLimitHit = $true
                if ($scanContent -match "resets ([A-Za-z0-9, :apm()UTC]+)") {
                    $resetText = $Matches[1].Trim()
                }
                break
            }
        }

        if ($rateLimitHit) {
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Magenta
            Write-Host "  RATE LIMIT DETECTED — Anthropic plan quota exhausted" -ForegroundColor Magenta
            if ($resetText) {
                Write-Host "  Quota resets: $resetText" -ForegroundColor Magenta

                # Try to parse the reset time. Format examples: "May 1, 12am (UTC)", "Apr 24, 5pm (UTC)"
                $resetDateTime = $null
                try {
                    $cleaned = ($resetText -replace '\(UTC\)', '').Trim()
                    # Inject current year if missing
                    if ($cleaned -notmatch '\d{4}') { $cleaned = "$cleaned $(Get-Date -Format yyyy)" }
                    $resetDateTime = [DateTime]::ParseExact(
                        $cleaned,
                        @('MMM d, htt yyyy','MMM d, hhtt yyyy','MMM dd, htt yyyy','MMM dd, hhtt yyyy','MMM d, h:mmtt yyyy'),
                        [System.Globalization.CultureInfo]::InvariantCulture,
                        [System.Globalization.DateTimeStyles]::AssumeUniversal
                    )
                } catch { }

                if ($resetDateTime) {
                    $now = (Get-Date).ToUniversalTime()
                    $waitSeconds = [int]($resetDateTime.ToUniversalTime() - $now).TotalSeconds
                    if ($waitSeconds -gt 14400) {
                        Write-Host "  Reset is $([math]::Round($waitSeconds/3600,1))h away (>4h). Exiting loop — restart manually after reset." -ForegroundColor Red
                        Write-Host "============================================================" -ForegroundColor Magenta
                        exit 2
                    }
                    elseif ($waitSeconds -gt 0) {
                        Write-Host "  Sleeping $([math]::Round($waitSeconds/60,1)) minutes until reset, then resuming..." -ForegroundColor Yellow
                        Write-Host "============================================================" -ForegroundColor Magenta
                        Start-Sleep -Seconds ($waitSeconds + 30)
                        $consecutiveZeroIterations = 0
                    }
                    else {
                        Write-Host "  Reset time has already passed — retrying in 60s..." -ForegroundColor Yellow
                        Write-Host "============================================================" -ForegroundColor Magenta
                        Start-Sleep -Seconds 60
                    }
                }
                else {
                    Write-Host "  Could not parse reset time. Sleeping 1h then retrying." -ForegroundColor Yellow
                    Write-Host "============================================================" -ForegroundColor Magenta
                    Start-Sleep -Seconds 3600
                }
            }
            else {
                Write-Host "  No reset time captured. Sleeping 1h then retrying." -ForegroundColor Yellow
                Write-Host "============================================================" -ForegroundColor Magenta
                Start-Sleep -Seconds 3600
            }
        }
        elseif ($consecutiveZeroIterations -ge 3) {
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Red
            Write-Host "  KILL SWITCH: 3 consecutive zero-token iterations" -ForegroundColor Red
            Write-Host "  No 'rate limit' signature found — likely auth/MCP failure." -ForegroundColor Red
            Write-Host "  Exiting to prevent another 1700-iteration death loop." -ForegroundColor Red
            Write-Host "  Check tempErr file: $tempErr" -ForegroundColor Red
            Write-Host "============================================================" -ForegroundColor Red
            exit 3
        }
        else {
            Write-Host "  Pausing 10 seconds before retry..." -ForegroundColor Red
            Start-Sleep -Seconds 10
        }
    }
    else {
        $consecutiveZeroIterations = 0
    }

    Write-Host ""
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Starting next iteration..." -ForegroundColor Green
    Write-Host ""
    $iteration++
}
