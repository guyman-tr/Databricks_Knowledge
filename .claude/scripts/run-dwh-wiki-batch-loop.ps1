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

# Resolve prompt file (bypasses locked .claude/commands/)
if ($SchemaName -eq "BI_DB_dbo") {
    $promptFile = Join-Path $repoRoot ".claude\prompts\build-wiki-bidb-batch.md"
} else {
    $promptFile = Join-Path $repoRoot ".claude\prompts\build-wiki-dwh-batch.md"
}

if (-not (Test-Path $claudePath)) {
    Write-Host "ERROR: claude not found at $claudePath" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $promptFile)) {
    Write-Host "ERROR: prompt file not found at $promptFile" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Wiki Batch Loop" -ForegroundColor Cyan
Write-Host "  Schema:  $SchemaName" -ForegroundColor Cyan
Write-Host "  Prompt:  $promptFile" -ForegroundColor Cyan
if ($DocLevel) {
    Write-Host "  Filter:  $DocLevel" -ForegroundColor Cyan
}
Write-Host "  Repo:    $repoRoot" -ForegroundColor Cyan
Write-Host "  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PREREQUISITE: Synapse MCP must be running in another window." -ForegroundColor Yellow
Write-Host "  If not, run:  & '.\.claude\scripts\start-synapse-mcp.ps1'" -ForegroundColor Yellow
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

    $batchMaxSeconds = 900   # 15 min hard ceiling per batch
    $postResultGrace = 30    # kill 30s after "result" event (conversation done but process lingers)

    $tempOut = Join-Path $env:TEMP "claude_wiki_batch_$iteration.jsonl"
    $tempErr = Join-Path $env:TEMP "claude_wiki_batch_err_$iteration.tmp"
    Remove-Item $tempOut -Force -ErrorAction SilentlyContinue
    Remove-Item $tempErr -Force -ErrorAction SilentlyContinue

    try {
        $promptContent = (Get-Content $promptFile -Raw) -replace '"', '\"'
        $proc = Start-Process -FilePath $claudePath `
            -ArgumentList "--dangerously-skip-permissions --verbose --output-format stream-json --print `"$promptContent`"" `
            -PassThru -NoNewWindow `
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
                                    Write-Host $block.text -NoNewline
                                } elseif ($block.type -eq "tool_use") {
                                    Write-Host "[Tool: $($block.name)]" -ForegroundColor Cyan
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
        Remove-Item $tempErr -Force -ErrorAction SilentlyContinue
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

    # Parity check: wiki Elements vs ALTER COLUMN COMMENT (loop continues on FAIL — next iteration fixes)
    $parityScript = Join-Path $repoRoot "tools\audit_wiki_alter_comment_parity.py"
    $parityStatusPath = Join-Path $repoRoot "knowledge\synapse\Wiki\$SchemaName\_parity_gate_last_run.txt"
    $parityJsonPath = Join-Path $repoRoot "knowledge\synapse\Wiki\$SchemaName\_parity_last_report.json"
    if (-not (Test-Path $parityScript)) {
        Write-Host ""
        Write-Host "  ERROR: Parity script missing: $parityScript" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
    Write-Host "  WIKI/ALTER COMMENT PARITY ($SchemaName)..." -ForegroundColor Cyan
    Push-Location $repoRoot
    try {
        & python $parityScript --under $SchemaName
        $parityExit = $LASTEXITCODE
        if ($parityExit -ne 0) {
            & python $parityScript --under $SchemaName --json | Set-Content -Encoding UTF8 $parityJsonPath
        }
        else {
            Remove-Item $parityJsonPath -Force -ErrorAction SilentlyContinue
        }
    } finally {
        Pop-Location
    }
    if ($parityExit -ne 0) {
        Write-Host ""
        Write-Host "  PARITY CHECK: FAIL — wiki Elements vs .alter.sql COMMENT mismatch or missing." -ForegroundColor Red
        Write-Host "  Next iteration continues; read _parity_gate_last_run.txt and fix before new objects." -ForegroundColor Yellow
        Write-Host "  Report: knowledge\synapse\Wiki\$SchemaName\_parity_last_report.json" -ForegroundColor DarkGray
        @(
            "STATUS=FAIL",
            "SCHEMA=$SchemaName",
            "RUN_AT=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
            "",
            "Next batch iteration: prioritize aligning wiki ## 4. Elements with ALTER COLUMN ... COMMENT per column.",
            "Use the same text encoding as merge_wiki_column_comments_into_alter.py (sql_string_for_comment).",
            "Machine-readable report: _parity_last_report.json (same folder).",
            "Re-audit: python tools\audit_wiki_alter_comment_parity.py --under $SchemaName",
        ) | Set-Content -Encoding UTF8 $parityStatusPath
    }
    else {
        Write-Host "  Parity gate: PASS" -ForegroundColor Green
        @(
            "STATUS=PASS",
            "SCHEMA=$SchemaName",
            "RUN_AT=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
            "",
            "Last audit: wiki Elements match ALTER COMMENT literals for all columns under this schema."
        ) | Set-Content -Encoding UTF8 $parityStatusPath
    }

    $schemaComplete = $false
    if (Test-Path $indexPath) {
        $content = Get-Content $indexPath -Raw -ErrorAction SilentlyContinue
        if ($content -and ($content -notmatch "Pending")) {
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
