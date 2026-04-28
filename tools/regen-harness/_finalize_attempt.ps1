[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] [string] $Schema,
    [Parameter(Mandatory=$true)] [string] $ObjectName,
    [Parameter(Mandatory=$false)] [int] $Attempt = 1
)

# ---------------------------------------------------------------------------
# Recovery helper: when run_writer.ps1 produced the wiki files but crashed
# during post-write parsing (e.g. stale file handle), this script:
#   1. Re-parses writer_raw_stream.jsonl into writer_log.md + writer_summary.json
# It does NOT call the writer again. It does NOT call the judge. The orchestrator
# still owns the judge step and the regen_summary.json roll-up.
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'
$harnessRoot = Split-Path -Parent $PSCommandPath
$repoRoot = (Get-Item (Join-Path $harnessRoot "..\..\")).FullName
$attemptDir = Join-Path $repoRoot ("audits\regen-sample\{0}\{1}\regen\attempt_{2}" -f $Schema, $ObjectName, $Attempt)

$rawStream = Join-Path $attemptDir "writer_raw_stream.jsonl"
if (-not (Test-Path $rawStream)) { throw "writer_raw_stream.jsonl not found at $rawStream" }

$rawAll = [System.IO.File]::ReadAllText($rawStream, [System.Text.UTF8Encoding]::new($false))
$assistantText = New-Object System.Text.StringBuilder
$inputTokens = 0; $outputTokens = 0; $costUsd = 0.0
$wroteFiles = New-Object System.Collections.Generic.HashSet[string]
foreach ($line in ($rawAll -split "`n")) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try {
        $obj = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -eq $obj) { continue }
        if ($obj.type -eq "assistant" -and $obj.message.content) {
            foreach ($block in $obj.message.content) {
                if ($block.type -eq "text" -and $block.text) {
                    [void]$assistantText.AppendLine($block.text)
                } elseif ($block.type -eq "tool_use" -and $block.name -eq "Write" -and $block.input -and $block.input.file_path) {
                    [void]$wroteFiles.Add($block.input.file_path)
                }
            }
        }
        if ($obj.type -eq "result") {
            if ($obj.usage) {
                $inputTokens  = [int]($obj.usage.input_tokens  | Select-Object -First 1)
                $outputTokens = [int]($obj.usage.output_tokens | Select-Object -First 1)
            }
            if ($obj.total_cost_usd) { $costUsd = [double]$obj.total_cost_usd }
            elseif ($obj.cost_usd)   { $costUsd = [double]$obj.cost_usd }
        }
    } catch {}
}

[System.IO.File]::WriteAllText(
    (Join-Path $attemptDir "writer_log.md"),
    $assistantText.ToString(),
    [System.Text.UTF8Encoding]::new($false)
)

$expectedMd      = Join-Path $attemptDir ("{0}.md" -f $ObjectName)
$expectedLineage = Join-Path $attemptDir ("{0}.lineage.md" -f $ObjectName)
$expectedReview  = Join-Path $attemptDir ("{0}.review-needed.md" -f $ObjectName)
$summary = [ordered]@{
    schema           = $Schema
    object           = $ObjectName
    attempt          = $Attempt
    elapsed_seconds  = $null
    exit_code        = 0
    cost_usd         = [Math]::Round($costUsd, 4)
    input_tokens     = $inputTokens
    output_tokens    = $outputTokens
    files_written    = @($wroteFiles)
    md_present       = (Test-Path $expectedMd)
    lineage_present  = (Test-Path $expectedLineage)
    review_present   = (Test-Path $expectedReview)
    md_path          = $expectedMd
    lineage_path     = $expectedLineage
    review_path      = $expectedReview
    prompt_path      = (Join-Path $attemptDir "writer_prompt.md")
    recovered        = $true
}
[System.IO.File]::WriteAllText(
    (Join-Path $attemptDir "writer_summary.json"),
    ($summary | ConvertTo-Json -Depth 10),
    [System.Text.UTF8Encoding]::new($false)
)
Write-Host ("Recovered writer_log.md + writer_summary.json for {0}.{1} attempt_{2} (in:{3} out:{4} cost:{5})" -f $Schema, $ObjectName, $Attempt, $inputTokens, $outputTokens, $costUsd) -ForegroundColor Green
