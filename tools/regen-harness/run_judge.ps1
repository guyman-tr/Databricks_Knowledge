[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]  [string] $Schema,
    [Parameter(Mandatory=$true)]  [string] $ObjectName,
    [Parameter(Mandatory=$true)]  [string] $WikiPath,
    [Parameter(Mandatory=$true)]  [string] $LineagePath,
    [Parameter(Mandatory=$false)] [string] $ReviewPath = "",
    [Parameter(Mandatory=$true)]  [string] $DdlPath,
    [Parameter(Mandatory=$false)] [string] $UpstreamBundlePath = "",
    [Parameter(Mandatory=$true)]  [string] $OutDir,
    [Parameter(Mandatory=$false)] [int]    $TimeoutSeconds = 900,
    [Parameter(Mandatory=$false)] [string] $Model = ""    # claude-cli model alias or full ID; "" = use claude.cmd default
)

# ---------------------------------------------------------------------------
# Adversarial Judge runner.
# Spawns a FRESH `claude.cmd` process with the judge prompt + inline file
# contents. Captures the stream-json output, extracts the <JUDGE_VERDICT>
# JSON block, and writes:
#   $OutDir/judge_verdict.json     (parsed JSON)
#   $OutDir/judge_log.md           (human-readable summary from claude)
#   $OutDir/judge_raw_stream.jsonl (full stream-json events)
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$harnessRoot = Split-Path -Parent $PSCommandPath
$promptTemplate = Join-Path $harnessRoot "prompts\judge.md"
if (-not (Test-Path $promptTemplate)) {
    throw "Judge prompt template not found: $promptTemplate"
}

$claudePath = "$env:APPDATA\npm\claude.cmd"
if (-not (Test-Path $claudePath)) {
    throw "claude.cmd not found at $claudePath"
}

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

function Read-Bounded([string] $Path, [int] $MaxBytes) {
    if (-not $Path -or -not (Test-Path $Path)) { return $null }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -le $MaxBytes) {
        return [System.Text.Encoding]::UTF8.GetString($bytes)
    }
    $cut = [System.Text.Encoding]::UTF8.GetString($bytes, 0, $MaxBytes)
    return $cut + "`n`n*[truncated to $($MaxBytes / 1024) KB]*`n"
}

# Compose the prompt: template + inputs.
$promptText = Get-Content $promptTemplate -Raw -Encoding UTF8
$inputs = New-Object System.Text.StringBuilder
[void]$inputs.AppendLine()
[void]$inputs.AppendLine("---")
[void]$inputs.AppendLine()
[void]$inputs.AppendLine("# Inputs for $Schema.$ObjectName")
[void]$inputs.AppendLine()
[void]$inputs.AppendLine("Schema: $Schema  Object: $ObjectName")
[void]$inputs.AppendLine()

function Append-Section([string] $Title, [string] $Path, [string] $Content) {
    [void]$inputs.AppendLine("## $Title")
    [void]$inputs.AppendLine()
    [void]$inputs.AppendLine("Source path: $Path")
    [void]$inputs.AppendLine()
    [void]$inputs.AppendLine('```markdown')
    [void]$inputs.AppendLine($Content)
    [void]$inputs.AppendLine('```')
    [void]$inputs.AppendLine()
}

$wiki    = Read-Bounded $WikiPath           (200 * 1024)
$lineage = Read-Bounded $LineagePath        (100 * 1024)
$review  = Read-Bounded $ReviewPath         ( 50 * 1024)
$ddl     = Read-Bounded $DdlPath            (100 * 1024)
$bundle  = Read-Bounded $UpstreamBundlePath (350 * 1024)

if (-not $wiki)    { throw "Wiki not found or empty: $WikiPath" }
if (-not $lineage) { Write-Host "  [judge] WARN: lineage missing: $LineagePath" -ForegroundColor Yellow; $lineage = "(no lineage file)" }
if (-not $ddl)     { Write-Host "  [judge] WARN: DDL missing: $DdlPath" -ForegroundColor Yellow; $ddl = "(no DDL file)" }
if (-not $bundle)  { $bundle = "(no upstream bundle - judge has only the wiki, lineage, and DDL)" }

Append-Section "Wiki under review" $WikiPath $wiki
Append-Section "Lineage file" $LineagePath $lineage
if ($review) { Append-Section "Review-needed sidecar" $ReviewPath $review }
Append-Section "DDL" $DdlPath $ddl
Append-Section "Pre-resolved upstream bundle" $UpstreamBundlePath $bundle

$fullPrompt = $promptText + "`n" + $inputs.ToString()

$promptFile = Join-Path $env:TEMP ("regen_judge_prompt_{0}_{1}.md" -f $Schema, $ObjectName)
[System.IO.File]::WriteAllText($promptFile, $fullPrompt, [System.Text.UTF8Encoding]::new($false))
$promptBytes = (Get-Item $promptFile).Length
Write-Host "  [judge] Prompt: $promptBytes bytes ($($Schema).$($ObjectName))" -ForegroundColor DarkGray

$tempOut = Join-Path $OutDir "judge_raw_stream.jsonl"
$tempErr = Join-Path $OutDir "judge_stderr.tmp"
Remove-Item $tempOut, $tempErr -Force -ErrorAction SilentlyContinue

# Allowed tools: Read only. The judge must NOT modify files. Bash is permitted
# so the judge can `head/find/etc.` but write tools are off-limits.
$argList = "--dangerously-skip-permissions --verbose --output-format stream-json --print --allowedTools Read,Bash,Grep,Glob"
if ($Model) {
    $argList = "$argList --model $Model"
    Write-Host ("  [judge] Model override: {0}" -f $Model) -ForegroundColor DarkGray
}

$repoRoot = (Get-Item (Join-Path $harnessRoot "..\..\")).FullName
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

while (-not $proc.HasExited) {
    Start-Sleep -Milliseconds 500
    if ($gotResult -and ($sw.Elapsed.TotalSeconds - $resultElapsed) -gt $postResultGrace) {
        Write-Host "  [judge] Post-result grace expired - killing PID $($proc.Id)." -ForegroundColor DarkYellow
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        break
    }
    if ($sw.Elapsed.TotalSeconds -gt $TimeoutSeconds) {
        Write-Host ("  [judge] TIMEOUT ({0}s) - killing." -f $TimeoutSeconds) -ForegroundColor Red
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
Write-Host "  [judge] claude exited code=$($proc.ExitCode) after ${elapsed}s." -ForegroundColor DarkGray

# ---------- Parse stream-json into final assistant text ----------
# Read with explicit UTF-8 encoding -- Windows Hebrew OEM code pages will
# otherwise mojibake any multi-byte UTF-8 character (em-dash, smart quotes).
# Tolerate the OS still flushing the redirected stdout handle after claude exited.
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
$assistantText = New-Object System.Text.StringBuilder
$inputTokens = 0; $outputTokens = 0; $costUsd = 0.0
$rawAll = Read-FileWithRetry $tempOut
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

$rawText = $assistantText.ToString()
[System.IO.File]::WriteAllText((Join-Path $OutDir "judge_log.md"), $rawText, [System.Text.UTF8Encoding]::new($false))

# ---------- Extract <JUDGE_VERDICT>...</JUDGE_VERDICT> ----------
$verdictJson = $null
$pattern = '<JUDGE_VERDICT>\s*(?:```json\s*)?([\s\S]*?)\s*(?:```\s*)?</JUDGE_VERDICT>'
$match = [regex]::Match($rawText, $pattern)
if ($match.Success) {
    $verdictJson = $match.Groups[1].Value.Trim()
    # Strip leading ```json fence if claude wrapped the JSON in code fences inside the markers.
    $fencePattern = '^```json\s*([\s\S]*?)\s*```$'
    if ($verdictJson -match $fencePattern) {
        $verdictJson = $matches[1].Trim()
    }
}

$verdictPath = Join-Path $OutDir "judge_verdict.json"
$summary = [ordered]@{
    schema           = $Schema
    object           = $ObjectName
    elapsed_seconds  = $elapsed
    exit_code        = $proc.ExitCode
    cost_usd         = [Math]::Round($costUsd, 4)
    input_tokens     = $inputTokens
    output_tokens    = $outputTokens
    verdict_json_present = [bool]$verdictJson
    parse_error      = $null
    verdict          = $null
}

if ($verdictJson) {
    try {
        $parsed = $verdictJson | ConvertFrom-Json
        $summary.verdict = $parsed
    } catch {
        $summary.parse_error = "$_"
        # Save raw payload so it's not lost
        [System.IO.File]::WriteAllText(
            (Join-Path $OutDir "judge_verdict_raw.txt"),
            $verdictJson,
            [System.Text.UTF8Encoding]::new($false)
        )
    }
} else {
    $summary.parse_error = 'No <JUDGE_VERDICT>...</JUDGE_VERDICT> markers found in judge output.'
}

[System.IO.File]::WriteAllText(
    $verdictPath,
    ($summary | ConvertTo-Json -Depth 20),
    [System.Text.UTF8Encoding]::new($false)
)

if ($summary.parse_error) {
    Write-Host "  [judge] WARN: $($summary.parse_error)" -ForegroundColor Yellow
} else {
    $score = $summary.verdict.weighted_score
    $verdict = $summary.verdict.verdict
    Write-Host "  [judge] $Schema/$ObjectName -> $verdict (score $score)" -ForegroundColor Cyan
}

Remove-Item $tempErr -Force -ErrorAction SilentlyContinue
Remove-Item $promptFile -Force -ErrorAction SilentlyContinue

exit 0
