# run-dwh-wiki-batch-loop-cursor.ps1
# ----------------------------------------------------------------------------
# Parallel wiki-documentation loop driven by the cursor-agent CLI instead of
# the Claude Code CLI. Different billing pool (Cursor Pro), so it does NOT
# share the Anthropic rate-limit cap with run-dwh-wiki-batch-loop.ps1.
#
# Recommended target: Dealing_dbo (default). eMoney_dbo and EXW_dbo are 100%
# documented as of 2026-04-21 — nothing pending there. Dealing_dbo has ~7
# P0 pending objects and several skipped tables that need attention. It is
# isolated from BI_DB_dbo (Claude's schema) so the two loops never touch the
# same _index.md and never compete for the same Pending objects.
#
# Authentication:
#   1. Install: irm 'https://cursor.com/install?win32=true' | iex
#   2. Login:   cursor-agent login (browser flow)
#   3. Verify:  cursor-agent status
#
# Usage:
#   .\run-dwh-wiki-batch-loop-cursor.ps1                       # defaults to Dealing_dbo
#   .\run-dwh-wiki-batch-loop-cursor.ps1 -SchemaName Dealing_dbo -Model composer-2-fast
#   .\run-dwh-wiki-batch-loop-cursor.ps1 -SchemaName eMoney_dbo  # only useful if new tables added

param(
    [string]$SchemaName = "Dealing_dbo",
    [string]$Model      = "",
    [string]$DocLevel   = ""
)

$ErrorActionPreference = 'Continue'

# ---- Locate cursor-agent binary ----
$cursorAgentCandidates = @(
    "$env:LOCALAPPDATA\cursor-agent\cursor-agent.cmd",
    "$env:USERPROFILE\.local\bin\cursor-agent.cmd",
    "$env:USERPROFILE\.local\bin\cursor-agent",
    "$env:USERPROFILE\.local\bin\agent.cmd",
    "$env:USERPROFILE\.local\bin\agent"
)
$cursorPath = $null
foreach ($c in $cursorAgentCandidates) {
    if (Test-Path $c) { $cursorPath = $c; break }
}
if (-not $cursorPath) {
    $found = Get-Command "cursor-agent" -ErrorAction SilentlyContinue
    if ($found) { $cursorPath = $found.Source }
}
if (-not $cursorPath) {
    Write-Host "ERROR: cursor-agent not found. Install via:" -ForegroundColor Red
    Write-Host "  irm 'https://cursor.com/install?win32=true' | iex" -ForegroundColor Red
    exit 1
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$indexPath = Join-Path $repoRoot "knowledge\synapse\Wiki\$SchemaName\_index.md"

# Resolve prompt file
if ($SchemaName -eq "BI_DB_dbo") {
    $basePromptFile = Join-Path $repoRoot ".claude\prompts\build-wiki-bidb-batch.md"
} else {
    $basePromptFile = Join-Path $repoRoot ".claude\prompts\build-wiki-dwh-batch.md"
}
if (-not (Test-Path $basePromptFile)) {
    Write-Host "ERROR: prompt file not found at $basePromptFile" -ForegroundColor Red
    exit 1
}
$promptFile = Join-Path $env:TEMP "cursor_wiki_prompt_$SchemaName.md"

# Per-schema default batch size (heavy weighted exception applied inside Get-NextBatch).
# Default 6 for cursor-agent on eMoney/EXW (smaller schemas, simpler models).
$schemaBatchSize = switch ($SchemaName) {
    "BI_DB_dbo"   { 8 }
    "DWH_dbo"     { 4 }
    "Dealing_dbo" { 4 }
    "eMoney_dbo"  { 6 }
    "EXW_dbo"     { 6 }
    default       { 4 }
}

# Dot-source shared batch picker
$libPath = Join-Path $PSScriptRoot "lib\Get-NextBatch.ps1"
if (Test-Path $libPath) {
    . $libPath
    $usePrePicker = $true
} else {
    Write-Host "WARN: Get-NextBatch.ps1 not found at $libPath - falling back to in-prompt discovery." -ForegroundColor Yellow
    $usePrePicker = $false
}

# ---- Pre-flight: cursor-agent auth ----
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Wiki Batch Loop (CURSOR-AGENT, wiki-only)" -ForegroundColor Cyan
Write-Host "  Binary:  $cursorPath" -ForegroundColor Cyan
Write-Host "  Schema:  $SchemaName" -ForegroundColor Cyan
Write-Host "  Model:   $(if ($Model) { $Model } else { '(default)' })" -ForegroundColor Cyan
Write-Host "  Prompt:  $promptFile" -ForegroundColor Cyan
Write-Host "  Repo:    $repoRoot" -ForegroundColor Cyan
Write-Host "  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Pre-flight: testing cursor-agent auth..." -ForegroundColor Yellow
$authStatus = & $cursorPath status 2>&1
if ($authStatus -match 'Not logged in') {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "  HARD FAIL: cursor-agent is not authenticated" -ForegroundColor Red
    Write-Host "  Run:  cursor-agent login" -ForegroundColor Red
    Write-Host "  Then re-run this script." -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    exit 1
}
Write-Host "  cursor-agent auth OK" -ForegroundColor Green

# ---- Pre-flight: Synapse MCP connection (same logic as Claude loop) ----
Write-Host "Pre-flight: testing Synapse MCP connection..." -ForegroundColor Yellow

$mcpJson = Join-Path $env:USERPROFILE ".cursor\mcp.json"
if (-not (Test-Path $mcpJson)) {
    $mcpJson = Join-Path $repoRoot ".mcp.json"
}
if (-not (Test-Path $mcpJson)) {
    Write-Host "HARD FAIL: mcp.json not found at ~/.cursor/mcp.json or $repoRoot\.mcp.json" -ForegroundColor Red
    exit 1
}

$mcpConfig = Get-Content $mcpJson -Raw | ConvertFrom-Json
$synEnv = $mcpConfig.mcpServers.synapse_sql.env
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
            timeout=15
        )
        method = f'SQL auth ({sql_user})'
    else:
        print('FAIL: No SQL creds in env or file.', file=sys.stderr)
        sys.exit(1)
    cur = conn.cursor()
    cur.execute('SELECT 1')
    cur.fetchone()
    conn.close()
    print(f'OK|{method}')
except Exception as e:
    print(f'FAIL: {e}', file=sys.stderr)
    sys.exit(1)
"@

$connTestFile = Join-Path $env:TEMP "synapse_conn_test_cursor.py"
[System.IO.File]::WriteAllText($connTestFile, $connTest, [System.Text.UTF8Encoding]::new($false))
$connResult = & python $connTestFile 2>&1
Remove-Item $connTestFile -Force -ErrorAction SilentlyContinue

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "  HARD FAIL: Synapse MCP connection test FAILED" -ForegroundColor Red
    Write-Host "  Server: $testServer" -ForegroundColor Red
    Write-Host "  Error:  $connResult" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    exit 1
}

$authInfo = ($connResult -split '\|')[1]
Write-Host "  Synapse connection OK ($testServer via $authInfo)" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop between iterations." -ForegroundColor Gray
Write-Host ""

# ---- Main loop ----
$iteration = 1
$consecutiveZeroIterations = 0

while ($true) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Iteration $iteration started..." -ForegroundColor Green
    Write-Host ""

    # Build per-iteration prompt
    $basePromptContent = Get-Content $basePromptFile -Raw
    $schemaScopeFooter = "`n`n## Schema argument`n`nSchema: $SchemaName`n`nProcess ONLY objects from the $SchemaName schema. Do NOT document objects from other schemas, even if they appear as cross-schema dependencies. Cross-schema dependencies are treated as Tier 4 (best available knowledge) - read their data if available but do NOT create wiki files for them.`n"
    $batchBlock = ""
    if ($usePrePicker) {
        try {
            $batchInfo = Get-NextBatch -SchemaName $SchemaName -BatchSize $schemaBatchSize -RepoRoot $repoRoot
            if ($batchInfo.Empty) {
                Write-Host ""
                Write-Host "============================================================" -ForegroundColor Magenta
                Write-Host "  PRE-PICKER: No pending objects in $SchemaName" -ForegroundColor Magenta
                Write-Host "  All SSDT tables either documented or blacklisted." -ForegroundColor Magenta
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
    [System.IO.File]::WriteAllText($promptFile, $promptContent, [System.Text.UTF8Encoding]::new($false))

    $batchMaxSeconds = 3000  # 50 min ceiling
    $postResultGrace = 30    # kill 30s after the agent prints DONE/finishes

    $tempOut = Join-Path $env:TEMP "cursor_wiki_batch_$iteration.txt"
    $tempErr = Join-Path $env:TEMP "cursor_wiki_batch_err_$iteration.tmp"
    Remove-Item $tempOut -Force -ErrorAction SilentlyContinue
    Remove-Item $tempErr -Force -ErrorAction SilentlyContinue

    # cursor-agent CLI args:
    #   -p / --print       non-interactive print mode
    #   --output-format    text | json | stream-json (we use text for portability)
    #   --force            auto-approve commands (--yolo alias)
    #   --approve-mcps     auto-approve all MCP servers
    #   --trust            trust workspace without prompting
    #   --workspace        explicit workspace path (the repo root)
    #   --model            optional model override
    $cursorArgs = @(
        "--print",
        "--output-format", "text",
        "--force",
        "--approve-mcps",
        "--trust",
        "--workspace", $repoRoot
    )
    if ($Model) {
        $cursorArgs += @("--model", $Model)
    }

    $hasOutput = $false
    try {
        $proc = Start-Process -FilePath $cursorPath `
            -ArgumentList $cursorArgs `
            -WorkingDirectory $repoRoot `
            -PassThru -NoNewWindow `
            -RedirectStandardInput $promptFile `
            -RedirectStandardOutput $tempOut `
            -RedirectStandardError $tempErr

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $lastSize = 0
        $lastGrowthAt = 0
        $idleKillSeconds = 600  # 10 min of zero output growth = process is hung

        while (-not $proc.HasExited) {
            Start-Sleep -Milliseconds 750

            if ($sw.Elapsed.TotalSeconds -gt $batchMaxSeconds) {
                Write-Host "`n  TIMEOUT ($($batchMaxSeconds)s): Killing hung cursor-agent process..." -ForegroundColor Red
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                break
            }

            if (Test-Path $tempOut) {
                $fi = Get-Item $tempOut -ErrorAction SilentlyContinue
                if ($null -ne $fi -and $fi.Length -gt $lastSize) {
                    $hasOutput = $true
                    $lastGrowthAt = $sw.Elapsed.TotalSeconds
                    try {
                        $stream = [System.IO.File]::Open($tempOut, 'Open', 'Read', 'ReadWrite')
                        $stream.Seek($lastSize, 'Begin') | Out-Null
                        $reader = New-Object System.IO.StreamReader($stream)
                        while ($null -ne ($line = $reader.ReadLine())) {
                            if ($line -match "(?i)BATCH|PHASE.*CHECKPOINT|Object \d+/\d+|HARD STOP|Schema:|COMPLETE") {
                                Write-Host $line -ForegroundColor Green
                            } elseif ($line -match "(?i)Phase \d+|Adversarial|Evaluator|Weighted Total|Score|PASS|FAIL") {
                                Write-Host $line -ForegroundColor DarkGray
                            } elseif ($line.Trim().Length -gt 0) {
                                $short = if ($line.Length -gt 200) { $line.Substring(0,200) + "..." } else { $line }
                                Write-Host "  $short" -ForegroundColor DarkGray
                            }
                        }
                        $lastSize = $stream.Position
                        $reader.Close()
                        $stream.Close()
                    } catch { }
                }
            }

            # Idle kill: if we got output before but it has been silent for too long.
            if ($hasOutput -and $lastGrowthAt -gt 0 -and ($sw.Elapsed.TotalSeconds - $lastGrowthAt) -gt $idleKillSeconds) {
                Write-Host "`n  IDLE KILL: no output for $idleKillSeconds s -- cursor-agent appears hung. Killing." -ForegroundColor Red
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                break
            }
        }
    } catch {
        Write-Host ""
        Write-Host "  cursor-agent process error: $_" -ForegroundColor Red
    } finally {
        if ($proc -and -not $proc.HasExited) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
        # Pre-deletion scan: capture rate-limit / quota signature from stdout
        $rateLimitFromStdout = $null
        if (Test-Path $tempOut) {
            try {
                $stdoutRaw = Get-Content $tempOut -Raw -ErrorAction SilentlyContinue
                if ($stdoutRaw -and $stdoutRaw -match "(quota|rate.?limit|usage limit reached|Too many requests|429)") {
                    $rateLimitFromStdout = $stdoutRaw
                }
            } catch { }
        }
        Remove-Item $tempOut -Force -ErrorAction SilentlyContinue
        # keep tempErr for debugging
    }

    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    Write-Host "  Iteration $iteration complete" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow

    # Schema completion check
    $schemaComplete = $false
    if (Test-Path $indexPath) {
        $content = Get-Content $indexPath -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $hasPending = ($content -match "Pending") -or ($content -match "Queued")
            $pendingCount = if ($content -match 'pending:\s*(\d+)') { [int]$Matches[1] } else { -1 }
            if (-not $hasPending -and $pendingCount -eq 0) {
                $schemaComplete = $true
            }
        }
    }
    if ($schemaComplete) {
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Magenta
        Write-Host "  SCHEMA COMPLETE - $SchemaName" -ForegroundColor Magenta
        Write-Host "  Total iterations: $iteration" -ForegroundColor Magenta
        Write-Host "============================================================" -ForegroundColor Magenta
        break
    }

    # Failure detection — cursor-agent doesn't expose per-call token cost,
    # so we use "no output" as the failure signal (analog of Claude's zero-tokens branch).
    if (-not $hasOutput) {
        $consecutiveZeroIterations++
        Write-Host ""
        Write-Host "  WARNING: No output produced - iteration may have failed (consecutive: $consecutiveZeroIterations)." -ForegroundColor Red

        if ($rateLimitFromStdout) {
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Magenta
            Write-Host "  RATE LIMIT / QUOTA detected in cursor-agent output" -ForegroundColor Magenta
            Write-Host "  Sleeping 1h, then retrying. If this persists, check Cursor account quotas." -ForegroundColor Yellow
            Write-Host "============================================================" -ForegroundColor Magenta
            Start-Sleep -Seconds 3600
        }
        elseif ($consecutiveZeroIterations -ge 3) {
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Red
            Write-Host "  KILL SWITCH: 3 consecutive zero-output iterations" -ForegroundColor Red
            Write-Host "  Likely auth/MCP failure. Check tempErr file: $tempErr" -ForegroundColor Red
            Write-Host "============================================================" -ForegroundColor Red
            exit 3
        }
        else {
            Write-Host "  Pausing 10 seconds before retry..." -ForegroundColor Red
            Start-Sleep -Seconds 10
        }
    } else {
        $consecutiveZeroIterations = 0
    }

    Write-Host ""
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Starting next iteration..." -ForegroundColor Green
    Write-Host ""
    $iteration++
}
