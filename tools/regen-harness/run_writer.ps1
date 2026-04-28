[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]  [string] $Schema,
    [Parameter(Mandatory=$true)]  [string] $ObjectName,
    [Parameter(Mandatory=$false)] [int]    $Attempt = 1,
    [Parameter(Mandatory=$false)] [int]    $TimeoutSeconds = 2400
)

# ---------------------------------------------------------------------------
# Regen harness writer runner.
# Spawns a FRESH `claude.cmd` process with the writer prompt assembled by
# build_writer_prompt.py. Captures the stream-json output, surfaces phase
# checkpoints / file writes in the console, and writes:
#   audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/writer_log.md
#   audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/writer_raw_stream.jsonl
#   audits/regen-sample/{Schema}/{Object}/regen/attempt_{N}/writer_summary.json
#
# Output wiki / lineage / review-needed files are written DIRECTLY by claude
# into attempt_{N}/ via the prompt's instructions. We just monitor and report.
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'
$harnessRoot = Split-Path -Parent $PSCommandPath
$repoRoot = (Get-Item (Join-Path $harnessRoot "..\..\")).FullName

$claudePath = "$env:APPDATA\npm\claude.cmd"
if (-not (Test-Path $claudePath)) { throw "claude.cmd not found at $claudePath" }

$attemptDir = Join-Path $repoRoot ("audits\regen-sample\{0}\{1}\regen\attempt_{2}" -f $Schema, $ObjectName, $Attempt)
$promptFile = Join-Path $attemptDir "writer_prompt.md"

if (-not (Test-Path $promptFile)) {
    Write-Host "  [writer] Prompt missing - running build_writer_prompt.py..." -ForegroundColor Yellow
    & python (Join-Path $harnessRoot "build_writer_prompt.py") --schema $Schema --object $ObjectName --attempt $Attempt
    if ($LASTEXITCODE -ne 0) { throw "build_writer_prompt.py failed with exit code $LASTEXITCODE" }
}

if (-not (Test-Path $promptFile)) { throw "Writer prompt still not present at $promptFile" }
$promptBytes = (Get-Item $promptFile).Length
Write-Host ("  [writer] Prompt: {0:N0} bytes ({1}.{2}, attempt {3})" -f $promptBytes, $Schema, $ObjectName, $Attempt) -ForegroundColor DarkGray

$tempOut = Join-Path $attemptDir "writer_raw_stream.jsonl"
$tempErr = Join-Path $attemptDir "writer_stderr.tmp"
Remove-Item $tempOut, $tempErr -Force -ErrorAction SilentlyContinue

# Allowed tools: Read, Write, Bash, Grep, Glob, plus all MCP tools (Synapse +
# Databricks). The writer runs in a working directory of the repo root so its
# relative `Read` tool calls match the repo layout the rules expect.
$argList = "--dangerously-skip-permissions --verbose --output-format stream-json --print"

$proc = Start-Process -FilePath $claudePath `
    -ArgumentList $argList `
    -WorkingDirectory $repoRoot `
    -PassThru -NoNewWindow `
    -RedirectStandardInput $promptFile `
    -RedirectStandardOutput $tempOut `
    -RedirectStandardError $tempErr

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$lastSize = 0
$gotResult = $false
$resultElapsed = 0
$postResultGrace = 30
$wroteFiles = New-Object System.Collections.Generic.HashSet[string]

while (-not $proc.HasExited) {
    Start-Sleep -Milliseconds 500

    if ($gotResult -and ($sw.Elapsed.TotalSeconds - $resultElapsed) -gt $postResultGrace) {
        Write-Host ("  [writer] Post-result grace expired ({0}s) - killing PID {1}." -f $postResultGrace, $proc.Id) -ForegroundColor DarkYellow
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        break
    }
    if ($sw.Elapsed.TotalSeconds -gt $TimeoutSeconds) {
        Write-Host ("  [writer] TIMEOUT ({0}s) - killing." -f $TimeoutSeconds) -ForegroundColor Red
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        break
    }

    if (-not (Test-Path $tempOut)) { continue }
    $fi = Get-Item $tempOut -ErrorAction SilentlyContinue
    if ($null -eq $fi -or $fi.Length -le $lastSize) { continue }

    try {
        $stream = [System.IO.File]::Open($tempOut, 'Open', 'Read', 'ReadWrite')
        $stream.Seek($lastSize, 'Begin') | Out-Null
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.UTF8Encoding]::new($false))
        while ($null -ne ($line = $reader.ReadLine())) {
            try {
                $obj = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($null -eq $obj) { continue }
                if ($obj.type -eq "assistant" -and $obj.message.content) {
                    foreach ($block in $obj.message.content) {
                        if ($block.type -eq "text" -and $block.text) {
                            $txt = $block.text
                            $elapsed = [math]::Round($sw.Elapsed.TotalSeconds)
                            if ($txt -match "PHASE GATE|OUTPUT CHECK|MCP PRE-FLIGHT|REGEN ABORT|CHECKPOINT") {
                                Write-Host ("  [{0}s] {1}" -f $elapsed, ($txt.Substring(0, [Math]::Min(160, $txt.Length)))) -ForegroundColor Cyan
                            }
                        } elseif ($block.type -eq "tool_use") {
                            $elapsed = [math]::Round($sw.Elapsed.TotalSeconds)
                            $toolName = $block.name
                            if ($block.input -and $block.input.file_path -and $toolName -eq "Write") {
                                $fp = $block.input.file_path
                                [void]$wroteFiles.Add($fp)
                                $fpDisp = $fp -replace '.*regen-sample\\', ''
                                Write-Host ("  [{0}s] Write: {1}" -f $elapsed, $fpDisp) -ForegroundColor Green
                            } elseif ($toolName -match "^mcp__synapse_sql") {
                                Write-Host ("  [{0}s] mcp:synapse" -f $elapsed) -ForegroundColor DarkCyan
                            } elseif ($toolName -match "^mcp__databricks_sql") {
                                Write-Host ("  [{0}s] mcp:databricks" -f $elapsed) -ForegroundColor DarkCyan
                            }
                        }
                    }
                }
                if ($obj.type -eq "result") {
                    $gotResult = $true
                    $resultElapsed = $sw.Elapsed.TotalSeconds
                }
            } catch {}
        }
        $reader.Close(); $stream.Close()
        $lastSize = $fi.Length
    } catch {}
}

$elapsed = [int]$sw.Elapsed.TotalSeconds
Write-Host ("  [writer] claude exited code={0} after {1}s" -f $proc.ExitCode, $elapsed) -ForegroundColor DarkGray

# ---------- Parse stream-json (UTF-8 explicit) ----------
$assistantText = New-Object System.Text.StringBuilder
$inputTokens = 0; $outputTokens = 0; $costUsd = 0.0
$rawAll = ""
# Tolerate the OS still flushing the redirected stdout handle after claude exited.
# Open with shared read/write access and retry briefly if the file is still locked.
function Read-FileWithRetry([string]$path, [int]$maxAttempts = 20, [int]$delayMs = 250) {
    for ($i = 1; $i -le $maxAttempts; $i++) {
        try {
            $fs = [System.IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
            try {
                $sr = New-Object System.IO.StreamReader($fs, [System.Text.UTF8Encoding]::new($false))
                try   { return $sr.ReadToEnd() }
                finally { $sr.Close() }
            } finally { $fs.Close() }
        } catch {
            if ($i -eq $maxAttempts) { throw }
            Start-Sleep -Milliseconds $delayMs
        }
    }
}
if (Test-Path $tempOut) {
    $rawAll = Read-FileWithRetry $tempOut
}
foreach ($line in ($rawAll -split "`n")) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try {
        $obj = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -eq $obj) { continue }
        if ($obj.type -eq "assistant" -and $obj.message.content) {
            foreach ($block in $obj.message.content) {
                if ($block.type -eq "text" -and $block.text) {
                    [void]$assistantText.AppendLine($block.text)
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

# ---------- Verify the three required output files exist ----------
$expectedMd       = Join-Path $attemptDir ("{0}.md" -f $ObjectName)
$expectedLineage  = Join-Path $attemptDir ("{0}.lineage.md" -f $ObjectName)
$expectedReview   = Join-Path $attemptDir ("{0}.review-needed.md" -f $ObjectName)

$summary = [ordered]@{
    schema           = $Schema
    object           = $ObjectName
    attempt          = $Attempt
    elapsed_seconds  = $elapsed
    exit_code        = $proc.ExitCode
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
    prompt_path      = $promptFile
}

[System.IO.File]::WriteAllText(
    (Join-Path $attemptDir "writer_summary.json"),
    ($summary | ConvertTo-Json -Depth 10),
    [System.Text.UTF8Encoding]::new($false)
)

if ($summary.md_present -and $summary.lineage_present -and $summary.review_present) {
    Write-Host ("  [writer] PASS: all 3 files written ({0}/{1}, attempt {2}, {3}s, `$" -f $Schema, $ObjectName, $Attempt, $elapsed) -NoNewline -ForegroundColor Green
    Write-Host ("{0})" -f ([Math]::Round($costUsd,4))) -ForegroundColor Green
    exit 0
} else {
    Write-Host "  [writer] FAIL: one or more output files missing." -ForegroundColor Red
    if (-not $summary.md_present)      { Write-Host "    missing: $expectedMd" -ForegroundColor Red }
    if (-not $summary.lineage_present) { Write-Host "    missing: $expectedLineage" -ForegroundColor Red }
    if (-not $summary.review_present)  { Write-Host "    missing: $expectedReview" -ForegroundColor Red }
    exit 1
}
