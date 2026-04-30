[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]  [string] $Schema,
    [Parameter(Mandatory=$true)]  [string] $ObjectName,
    [Parameter(Mandatory=$false)] [int]    $Attempt = 1,
    [Parameter(Mandatory=$false)] [int]    $TimeoutSeconds = 2400,
    [Parameter(Mandatory=$false)] [string] $Model = ""    # claude-cli model alias or full ID; "" = use claude.cmd default (currently Opus)
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
if ($Model) {
    $argList = "$argList --model $Model"
    Write-Host ("  [writer] Model override: {0}" -f $Model) -ForegroundColor DarkGray
}

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

# Kill the entire process tree (claude.cmd -> node.exe). Stop-Process alone
# only kills the cmd.exe wrapper; node.exe keeps the stdout handle open and
# the parent loop hangs forever waiting on HasExited.
function Kill-ProcessTree([int]$pidToKill, [string]$prefix) {
    try {
        $tk = & cmd.exe /c "taskkill /T /F /PID $pidToKill" 2>&1
        Write-Host "  $prefix taskkill /T /F /PID $pidToKill -> $tk" -ForegroundColor DarkYellow
    } catch {
        Write-Host "  $prefix taskkill failed: $_" -ForegroundColor Red
    }
    try { Stop-Process -Id $pidToKill -Force -ErrorAction SilentlyContinue } catch {}
}

while ($true) {
    # Refresh cached state first; HasExited can lag without an explicit refresh.
    try { $proc.Refresh() } catch {}
    if ($proc.HasExited) { break }

    # Hard timeout check FIRST, before any potentially-blocking I/O.
    if ($sw.Elapsed.TotalSeconds -gt $TimeoutSeconds) {
        Write-Host ("  [writer] TIMEOUT ({0}s) - killing process tree." -f $TimeoutSeconds) -ForegroundColor Red
        Kill-ProcessTree $proc.Id "[writer]"
        break
    }
    if ($gotResult -and ($sw.Elapsed.TotalSeconds - $resultElapsed) -gt $postResultGrace) {
        Write-Host ("  [writer] Post-result grace expired ({0}s) - killing process tree." -f $postResultGrace) -ForegroundColor DarkYellow
        Kill-ProcessTree $proc.Id "[writer]"
        break
    }

    Start-Sleep -Milliseconds 500

    # Non-blocking incremental scan. We deliberately AVOID StreamReader.ReadLine()
    # because it blocks forever when the source flushes a partial line and keeps
    # the handle open (claude.cmd's node child does this). Read whatever bytes
    # exist, scan with simple regex, and move on.
    if (-not (Test-Path $tempOut)) { continue }
    $fi = Get-Item $tempOut -ErrorAction SilentlyContinue
    if ($null -eq $fi -or $fi.Length -le $lastSize) { continue }

    try {
        $newBytes = [int]($fi.Length - $lastSize)
        if ($newBytes -le 0) { continue }
        $stream = [System.IO.File]::Open($tempOut, 'Open', 'Read', 'ReadWrite')
        try {
            $stream.Seek($lastSize, 'Begin') | Out-Null
            $buf = New-Object byte[] $newBytes
            $read = $stream.Read($buf, 0, $newBytes)
        } finally { $stream.Close() }
        if ($read -le 0) { continue }
        $chunk = [System.Text.Encoding]::UTF8.GetString($buf, 0, $read)
        $lastSize = $fi.Length
        $elapsed = [math]::Round($sw.Elapsed.TotalSeconds)

        if (-not $gotResult -and $chunk -match '"type"\s*:\s*"result"') {
            $gotResult = $true
            $resultElapsed = $sw.Elapsed.TotalSeconds
        }

        # Surface phase markers — best-effort substring match against escaped JSON text.
        $phaseMatches = [regex]::Matches($chunk, '(PHASE GATE|OUTPUT CHECK|MCP PRE-FLIGHT|REGEN ABORT|CHECKPOINT)[^"]{0,160}')
        foreach ($m in $phaseMatches) {
            $snippet = ($m.Value -replace '\\n',' ' -replace '\\"','"').Trim()
            Write-Host ("  [{0}s] {1}" -f $elapsed, $snippet.Substring(0, [Math]::Min(160, $snippet.Length))) -ForegroundColor Cyan
        }

        # Surface Write tool_use events — the file_path appears in the JSON as
        # "name":"Write" ... "file_path":"...". Scan for fresh Write events.
        $writeMatches = [regex]::Matches($chunk, '"name"\s*:\s*"Write"[^}]*?"file_path"\s*:\s*"([^"]+)"')
        foreach ($m in $writeMatches) {
            $fp = ($m.Groups[1].Value -replace '\\\\','\').Trim()
            if (-not $wroteFiles.Contains($fp)) {
                [void]$wroteFiles.Add($fp)
                $fpDisp = $fp -replace '.*regen-sample\\', '' -replace '.*regen-sample/', ''
                Write-Host ("  [{0}s] Write: {1}" -f $elapsed, $fpDisp) -ForegroundColor Green
            }
        }

        if ($chunk -match '"name"\s*:\s*"mcp__synapse_sql') {
            Write-Host ("  [{0}s] mcp:synapse" -f $elapsed) -ForegroundColor DarkCyan
        }
        if ($chunk -match '"name"\s*:\s*"mcp__databricks_sql') {
            Write-Host ("  [{0}s] mcp:databricks" -f $elapsed) -ForegroundColor DarkCyan
        }
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
