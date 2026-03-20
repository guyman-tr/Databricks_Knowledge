param(
    [string]$SchemaName = "",
    [string]$DocLevel = ""
)

$ErrorActionPreference = 'Continue'

if (-not $SchemaName) {
    $SchemaName = Read-Host "Schema Name (default: DWH_dbo)"
    if (-not $SchemaName) { $SchemaName = "DWH_dbo" }
}

# Pick the right command based on schema
if ($SchemaName -eq "BI_DB_dbo") {
    $batchCommand = "/build-wiki-bidb-batch"
    $commandArgs = "$SchemaName $DocLevel".Trim()
} else {
    $batchCommand = "/build-wiki-dwh-batch"
    $commandArgs = $SchemaName
}

$claudePath = "$env:APPDATA\npm\claude.cmd"
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$indexPath = Join-Path $repoRoot "knowledge\synapse\Wiki\$SchemaName\_index.md"

if (-not (Test-Path $claudePath)) {
    Write-Host "ERROR: claude not found at $claudePath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Wiki Batch Loop" -ForegroundColor Cyan
Write-Host "  Schema:  $SchemaName" -ForegroundColor Cyan
Write-Host "  Command: $batchCommand" -ForegroundColor Cyan
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

    try {
        & $claudePath --dangerously-skip-permissions --verbose --output-format stream-json --print "run $batchCommand $commandArgs" 2>$null | ForEach-Object {
            try {
                $obj = $_ | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($null -eq $obj) { return }
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
                    if ($obj.usage) {
                        $inputTokens  = $obj.usage.input_tokens
                        $outputTokens = $obj.usage.output_tokens
                    }
                    if ($obj.cost_usd) { $costUsd = $obj.cost_usd }
                }
            } catch {
                # JSON parse error - skip line
            }
        }
    } catch {
        Write-Host ""
        Write-Host "  Claude Code process error: $_" -ForegroundColor Red
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
