<#
.SYNOPSIS
    Overnight batch loop for DWH wiki documentation pipeline.
    Processes hundreds of objects across fresh sessions — one batch per session, no drift.

.DESCRIPTION
    Spawns fresh Claude Code (or Cursor, future) sessions in a loop.
    Each session documents one batch from _index.md, then exits.
    The loop detects completion, logs everything, auto-commits, and tracks quality.

.PARAMETER SchemaName
    Target schema (default: BI_DB_dbo)

.PARAMETER Engine
    Which CLI engine to use: "claude" (default) or "cursor" (future)

.PARAMETER MaxIterations
    Safety cap — stop after N batches even if objects remain (default: 200)

.PARAMETER BatchTimeout
    Seconds before killing a hung batch (default: 1200 = 20 min)

.PARAMETER AutoCommit
    Commit after each successful batch (default: $true)

.PARAMETER AutoPush
    Push to remote after each commit (default: $false)

.PARAMETER DryRun
    Show what would happen without executing (default: $false)

.EXAMPLE
    .\run-overnight-batch.ps1 -SchemaName BI_DB_dbo
    .\run-overnight-batch.ps1 -SchemaName BI_DB_dbo -MaxIterations 50 -AutoPush
    .\run-overnight-batch.ps1 -SchemaName BI_DB_dbo -DryRun
#>

param(
    [string]$SchemaName = "BI_DB_dbo",
    [ValidateSet("claude", "cursor")]
    [string]$Engine = "claude",
    [int]$MaxIterations = 200,
    [int]$BatchTimeout = 1200,
    [bool]$AutoCommit = $true,
    [bool]$AutoPush = $false,
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'

# ─── Paths ───────────────────────────────────────────────────────────────────
$repoRoot      = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$indexPath      = Join-Path $repoRoot "knowledge\synapse\Wiki\$SchemaName\_index.md"
$promptFile     = Join-Path $repoRoot ".claude\prompts\build-wiki-bidb-batch.md"
$logDir         = Join-Path $repoRoot ".claude\logs"
$logFile        = Join-Path $logDir "overnight_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$metricsFile    = Join-Path $logDir "overnight_$(Get-Date -Format 'yyyyMMdd_HHmmss')_metrics.csv"

if ($SchemaName -ne "BI_DB_dbo") {
    $promptFile = Join-Path $repoRoot ".claude\prompts\build-wiki-dwh-batch.md"
}

# ─── Engine resolution ───────────────────────────────────────────────────────
$claudePath = "$env:APPDATA\npm\claude.cmd"
if (-not (Test-Path $claudePath)) {
    $claudePath = (Get-Command claude -ErrorAction SilentlyContinue).Source
}

if ($Engine -eq "cursor") {
    Write-Host "ERROR: Cursor headless mode is not yet supported." -ForegroundColor Red
    Write-Host "  Cursor CLI does not have a --print equivalent for non-interactive execution." -ForegroundColor Red
    Write-Host "  Use -Engine claude (default) for overnight runs." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $claudePath)) {
    Write-Host "ERROR: Claude CLI not found. Install via: npm install -g @anthropic-ai/claude-code" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $promptFile)) {
    Write-Host "ERROR: Prompt file not found: $promptFile" -ForegroundColor Red
    Write-Host "  Create it first or run from the Databricks_Knowledge repo root." -ForegroundColor Red
    exit 1
}

# ─── Logging ─────────────────────────────────────────────────────────────────
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

function Log {
    param([string]$Message, [string]$Color = "White", [switch]$NoConsole)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "[$ts] $Message"
    Add-Content -Path $logFile -Value $entry -ErrorAction SilentlyContinue
    if (-not $NoConsole) {
        Write-Host $entry -ForegroundColor $Color
    }
}

# ─── Index parser ────────────────────────────────────────────────────────────
function Get-PendingCount {
    if (-not (Test-Path $indexPath)) { return -1 }
    $content = Get-Content $indexPath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return -1 }
    return ([regex]::Matches($content, "Pending")).Count
}

function Get-DocumentedCount {
    if (-not (Test-Path $indexPath)) { return 0 }
    $content = Get-Content $indexPath -Raw -ErrorAction SilentlyContinue
    if ($content -match "documented:\s*(\d+)") { return [int]$Matches[1] }
    return 0
}

function Get-QualityAvg {
    if (-not (Test-Path $indexPath)) { return 0 }
    $content = Get-Content $indexPath -Raw -ErrorAction SilentlyContinue
    if ($content -match "quality_avg:\s*([\d.]+)") { return [double]$Matches[1] }
    return 0
}

function Get-LastBatch {
    if (-not (Test-Path $indexPath)) { return 0 }
    $content = Get-Content $indexPath -Raw -ErrorAction SilentlyContinue
    if ($content -match "last_batch:\s*(\d+)") { return [int]$Matches[1] }
    return 0
}

# ─── Git helpers ─────────────────────────────────────────────────────────────
function Invoke-AutoCommit {
    param([int]$BatchNum, [int]$ObjCount)
    Push-Location $repoRoot
    try {
        $status = git status --short -- "knowledge/synapse/Wiki/$SchemaName/" 2>&1
        if (-not $status) {
            Log "  No changes to commit." "DarkGray"
            return
        }
        git add "knowledge/synapse/Wiki/$SchemaName/" 2>&1 | Out-Null
        $msg = "feat: $SchemaName Batch $BatchNum ($ObjCount objects) [overnight]"
        git commit -m $msg 2>&1 | Out-Null
        Log "  Committed: $msg" "Green"

        if ($AutoPush) {
            git push 2>&1 | Out-Null
            Log "  Pushed to remote." "Green"
        }
    } catch {
        Log "  Git error: $_" "Red"
    } finally {
        Pop-Location
    }
}

# ─── Quality drift detection ────────────────────────────────────────────────
$qualityHistory = @()

function Test-QualityDrift {
    param([double]$CurrentAvg)
    if ($qualityHistory.Count -lt 3) { return $false }
    $recent3 = $qualityHistory[-3..-1]
    $trend = $recent3[2] - $recent3[0]
    if ($trend -lt -1.0) {
        Log "  DRIFT WARNING: Quality declining ($($recent3[0]) -> $($recent3[2]))" "Yellow"
        return $true
    }
    return $false
}

# ─── Banner ──────────────────────────────────────────────────────────────────
$pendingBefore = Get-PendingCount
$docBefore     = Get-DocumentedCount
$qualBefore    = Get-QualityAvg

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  OVERNIGHT BATCH LOOP" -ForegroundColor Cyan
Write-Host "  Schema:         $SchemaName" -ForegroundColor Cyan
Write-Host "  Engine:         $Engine" -ForegroundColor Cyan
Write-Host "  Prompt:         $promptFile" -ForegroundColor Cyan
Write-Host "  Max Iterations: $MaxIterations" -ForegroundColor Cyan
Write-Host "  Batch Timeout:  ${BatchTimeout}s" -ForegroundColor Cyan
Write-Host "  Auto-Commit:    $AutoCommit" -ForegroundColor Cyan
Write-Host "  Auto-Push:      $AutoPush" -ForegroundColor Cyan
Write-Host "  Log File:       $logFile" -ForegroundColor Cyan
Write-Host "  Pending:        $pendingBefore objects" -ForegroundColor Cyan
Write-Host "  Documented:     $docBefore objects" -ForegroundColor Cyan
Write-Host "  Quality Avg:    $qualBefore" -ForegroundColor Cyan
Write-Host "  Started:        $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PREREQUISITE: Synapse MCP server must be running." -ForegroundColor Yellow
Write-Host "  Start it:  & '.\.claude\scripts\start-synapse-mcp.ps1'" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C between iterations to stop gracefully." -ForegroundColor Gray
Write-Host ""

Log "Overnight batch started - $SchemaName, engine=$Engine, pending=$pendingBefore" "Cyan"

# Metrics CSV header
"Iteration,BatchNum,StartTime,Duration_s,InputTokens,OutputTokens,Cost_USD,DocBefore,DocAfter,QualityAvg,Pending,Status" | Out-File $metricsFile -Encoding utf8

if ($DryRun) {
    Write-Host "[DRY RUN] Would loop up to $MaxIterations times processing pending objects." -ForegroundColor Magenta
    Write-Host "[DRY RUN] Prompt file content:" -ForegroundColor Magenta
    foreach ($pline in (Get-Content $promptFile)) { Write-Host ("  " + $pline) -ForegroundColor DarkGray }
    exit 0
}

# ─── Main loop ───────────────────────────────────────────────────────────────
$iteration       = 1
$totalCostUsd    = 0.0
$totalInput      = 0
$totalOutput     = 0
$consecutiveFails = 0
$startTime       = Get-Date

while ($iteration -le $MaxIterations) {
    $pending = Get-PendingCount
    if ($pending -le 0) {
        Log "No pending objects remaining. Schema complete!" "Magenta"
        break
    }

    $batchStart   = Get-Date
    $docBefore    = Get-DocumentedCount
    $batchNumBefore = Get-LastBatch
    $inputTokens  = 0
    $outputTokens = 0
    $costUsd      = 0.0
    $batchStatus  = "unknown"

    Log "----------------------------------------" "DarkGray"
    $iterMsg = "Iteration $iteration / $MaxIterations -- Pending: $pending -- Engine: $Engine"
    Log $iterMsg "Green"

    $tempOut = Join-Path $env:TEMP "overnight_batch_$iteration.jsonl"
    $tempErr = Join-Path $env:TEMP "overnight_batch_err_$iteration.tmp"
    Remove-Item $tempOut -Force -ErrorAction SilentlyContinue
    Remove-Item $tempErr -Force -ErrorAction SilentlyContinue

    try {
        $promptContent = (Get-Content $promptFile -Raw) -replace '"', '\"'

        $proc = Start-Process -FilePath $claudePath `
            -ArgumentList "--dangerously-skip-permissions --verbose --output-format stream-json --print `"$promptContent`"" `
            -WorkingDirectory $repoRoot `
            -PassThru -NoNewWindow `
            -RedirectStandardOutput $tempOut `
            -RedirectStandardError $tempErr

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $lastSize = 0
        $gotResult = $false
        $resultElapsed = 0
        $postResultGrace = 30

        while (-not $proc.HasExited) {
            Start-Sleep -Milliseconds 500

            # Post-result grace period
            if ($gotResult -and ($sw.Elapsed.TotalSeconds - $resultElapsed) -gt $postResultGrace) {
                Log "  Post-result cleanup: killing lingering process." "DarkYellow"
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                break
            }
            # Hard timeout
            if ($sw.Elapsed.TotalSeconds -gt $BatchTimeout) {
                $timeoutMsg = '  TIMEOUT ({0}s): Killing hung process.' -f $BatchTimeout
                Log $timeoutMsg "Red"
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                $batchStatus = "timeout"
                break
            }

            # Stream output
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
                                $inputTokens  = [int]($obj.usage.input_tokens)
                                $outputTokens = [int]($obj.usage.output_tokens)
                            }
                            if ($obj.cost_usd) { $costUsd = [double]($obj.cost_usd) }
                            $batchStatus = "success"
                        }
                    } catch { }
                }
                $lastSize = $stream.Position
                $reader.Close()
                $stream.Close()
            } catch { }
        }
    } catch {
        Log "  Process error: $_" "Red"
        $batchStatus = "error"
    } finally {
        if ($proc -and -not $proc.HasExited) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
        Remove-Item $tempOut -Force -ErrorAction SilentlyContinue
        Remove-Item $tempErr -Force -ErrorAction SilentlyContinue
    }

    $duration     = (Get-Date) - $batchStart
    $durationSec  = [math]::Round($duration.TotalSeconds, 0)
    $totalCostUsd += $costUsd
    $totalInput   += $inputTokens
    $totalOutput  += $outputTokens

    # Post-batch metrics
    $docAfter      = Get-DocumentedCount
    $batchNumAfter = Get-LastBatch
    $qualAfter     = Get-QualityAvg
    $pendingAfter  = Get-PendingCount
    $objsThisBatch = $docAfter - $docBefore

    $qualityHistory += $qualAfter

    # Detect if the batch actually produced output
    if ($objsThisBatch -eq 0 -and $batchStatus -ne "timeout") {
        $batchStatus = "no_output"
        $consecutiveFails++
    } else {
        $consecutiveFails = 0
    }

    # Log metrics
    Log "" "DarkGray"
    Log "  Status:     $batchStatus" $(if ($batchStatus -eq "success") { "Green" } else { "Red" })
    Log "  Duration:   ${durationSec}s" "Yellow"
    Log "  Objects:    +$objsThisBatch documented, $docAfter total" "Yellow"
    Log "  Quality:    $qualAfter" "Yellow"
    Log "  Tokens:     $inputTokens input, $outputTokens output" "Yellow"
    Log "  Cost:       `$$([math]::Round($costUsd, 4))" "Yellow"
    Log "  Pending:    $pendingAfter remaining" "Yellow"
    $totalCostRounded = [math]::Round($totalCostUsd, 4)
    $totalsMsg = '  Totals:     ${0} cost, {1} input, {2} output tokens' -f $totalCostRounded, $totalInput, $totalOutput
    Log $totalsMsg "DarkGray"

    # Write metrics CSV row
    $batchStartStr = if ($batchStart) { $batchStart.ToString('HH:mm:ss') } else { 'N/A' }
    $costRounded = [math]::Round($costUsd, 4)
    $csvRow = "$iteration,$batchNumAfter,$batchStartStr,$durationSec,$inputTokens,$outputTokens,$costRounded,$docBefore,$docAfter,$qualAfter,$pendingAfter,$batchStatus"
    $csvRow | Add-Content $metricsFile

    # Auto-commit
    if ($AutoCommit -and $objsThisBatch -gt 0) {
        Invoke-AutoCommit -BatchNum $batchNumAfter -ObjCount $objsThisBatch
    }

    # Drift detection
    Test-QualityDrift -CurrentAvg $qualAfter | Out-Null

    # Failure circuit breaker
    if ($consecutiveFails -ge 3) {
        Log "ABORT: 3 consecutive batches produced no output. Stopping." "Red"
        $batchStatus = "aborted"
        break
    }

    # Pause on failure before retry
    if ($batchStatus -ne "success") {
        Log "  Pausing 15s before retry..." "DarkYellow"
        Start-Sleep -Seconds 15
    }

    # Check completion
    if ($pendingAfter -le 0) {
        Log "All objects documented!" "Magenta"
        break
    }

    Write-Host ""
    $iteration++
}

# ─── Summary ─────────────────────────────────────────────────────────────────
$elapsed = (Get-Date) - $startTime

Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "  OVERNIGHT RUN COMPLETE" -ForegroundColor Magenta
Write-Host "  Schema:          $SchemaName" -ForegroundColor Magenta
Write-Host "  Iterations:      $($iteration)" -ForegroundColor Magenta
Write-Host "  Duration:        $([math]::Round($elapsed.TotalHours, 1)) hours" -ForegroundColor Magenta
Write-Host "  Documented:      $docBefore -> $(Get-DocumentedCount)" -ForegroundColor Magenta
Write-Host "  Quality Avg:     $(Get-QualityAvg)" -ForegroundColor Magenta
Write-Host "  Pending:         $(Get-PendingCount) remaining" -ForegroundColor Magenta
Write-Host "  Total Cost:      `$$([math]::Round($totalCostUsd, 2)) USD" -ForegroundColor Magenta
Write-Host "  Total Tokens:    $totalInput input, $totalOutput output" -ForegroundColor Magenta
Write-Host "  Log:             $logFile" -ForegroundColor Magenta
Write-Host "  Metrics CSV:     $metricsFile" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta

$summaryMsg = "Overnight run complete - " + $iteration + " iterations, " + [math]::Round($elapsed.TotalHours,1) + "h, $" + [math]::Round($totalCostUsd,2)
Log $summaryMsg "Magenta"
