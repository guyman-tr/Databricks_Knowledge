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
$promptFile = Join-Path $env:TEMP "claude_wiki_prompt_$SchemaName.md"
$promptContent = (Get-Content $basePromptFile -Raw) + "`n`n## Schema argument`n`nSchema: $SchemaName`n`nProcess ONLY objects from the $SchemaName schema. Do NOT document objects from other schemas, even if they appear as cross-schema dependencies. Cross-schema dependencies are treated as Tier 4 (best available knowledge) - read their data if available but do NOT create wiki files for them.`n"
[System.IO.File]::WriteAllText($promptFile, $promptContent, [System.Text.UTF8Encoding]::new($false))

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
Write-Host "  Prompt:  $promptFile" -ForegroundColor Cyan
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

$iteration = 1
$totalCostUsd = 0

while ($true) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Iteration $iteration started..." -ForegroundColor Green
    Write-Host ""

    $inputTokens = 0
    $outputTokens = 0
    $costUsd = 0

    $batchMaxSeconds = 2700  # 45 min ceiling — DWH objects with 50-90 col tables need 20-40 min per batch
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
        Remove-Item $tempOut -Force -ErrorAction SilentlyContinue
        # Keep stderr for MCP debugging: $tempErr
        # Remove-Item $tempErr -Force -ErrorAction SilentlyContinue
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

    $schemaComplete = $false
    if (Test-Path $indexPath) {
        $content = Get-Content $indexPath -Raw -ErrorAction SilentlyContinue
        if ($content -and ($content -notmatch "Pending") -and ($content -notmatch "Queued")) {
            $schemaComplete = $true
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
        Write-Host ""
        Write-Host "  WARNING: No tokens used - iteration may have failed." -ForegroundColor Red
        Write-Host "  Pausing 10 seconds before retry..." -ForegroundColor Red
        Start-Sleep -Seconds 10
    }

    Write-Host ""
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Starting next iteration..." -ForegroundColor Green
    Write-Host ""
    $iteration++
}
