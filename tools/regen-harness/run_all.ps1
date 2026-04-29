[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] [string] $ManifestPath = "",
    [Parameter(Mandatory=$false)] [int]    $MaxAttempts = 2,
    [Parameter(Mandatory=$false)] [int]    $WriterTimeoutSeconds = 2400,
    [Parameter(Mandatory=$false)] [int]    $JudgeTimeoutSeconds = 900,
    [Parameter(Mandatory=$false)] [string] $OnlySchema = "",
    [Parameter(Mandatory=$false)] [string] $OnlyBucket = "",
    [Parameter(Mandatory=$false)] [switch] $SkipFinishedObjects,
    [Parameter(Mandatory=$false)] [switch] $SkipCompare,
    [Parameter(Mandatory=$false)] [int]    $StartAt = 1,
    [Parameter(Mandatory=$false)] [string] $SummaryOutputName = "_summary"
)

# ---------------------------------------------------------------------------
# Top-level driver. Reads manifest.csv, calls regen_one.ps1 for each row
# sequentially. After all rows are processed, calls compare_one.py for the
# whole batch (judge against current/) and summarize.py to produce
# audits/regen-sample/_summary.md.
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Continue'
$harnessRoot = Split-Path -Parent $PSCommandPath
$repoRoot = (Get-Item (Join-Path $harnessRoot "..\..\")).FullName

if (-not $ManifestPath) {
    $ManifestPath = Join-Path $repoRoot "audits\regen-sample\manifest.csv"
}
if (-not (Test-Path $ManifestPath)) {
    Write-Host "ERROR: manifest not found: $ManifestPath" -ForegroundColor Red
    exit 1
}

$rows = Import-Csv $ManifestPath
if ($OnlySchema) { $rows = $rows | Where-Object { $_.Schema -eq $OnlySchema } }
if ($OnlyBucket) { $rows = $rows | Where-Object { $_.Bucket -eq $OnlyBucket } }

$total = ($rows | Measure-Object).Count
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ("  Regen Harness -- run_all  ({0} objects)" -f $total) -ForegroundColor Cyan
Write-Host ("  Manifest: {0}" -f $ManifestPath) -ForegroundColor Cyan
Write-Host ("  Max attempts: {0}  Writer timeout: {1}s  Judge timeout: {2}s" -f $MaxAttempts, $WriterTimeoutSeconds, $JudgeTimeoutSeconds) -ForegroundColor Cyan
if ($OnlySchema) { Write-Host ("  Filter schema: {0}" -f $OnlySchema) -ForegroundColor Cyan }
if ($OnlyBucket) { Write-Host ("  Filter bucket: {0}" -f $OnlyBucket) -ForegroundColor Cyan }
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$idx = 0
$swAll = [System.Diagnostics.Stopwatch]::StartNew()
$results = @()

foreach ($row in $rows) {
    $idx++
    if ($idx -lt $StartAt) {
        Write-Host ("[{0}/{1}] SKIP (StartAt={2}): {3}.{4}" -f $idx, $total, $StartAt, $row.Schema, $row.Object) -ForegroundColor DarkGray
        continue
    }

    $regenSummary = Join-Path $repoRoot ("audits\regen-sample\{0}\{1}\regen\regen_summary.json" -f $row.Schema, $row.Object)
    if ($SkipFinishedObjects -and (Test-Path $regenSummary)) {
        Write-Host ("[{0}/{1}] SKIP (already done): {2}.{3}" -f $idx, $total, $row.Schema, $row.Object) -ForegroundColor DarkGray
        continue
    }

    Write-Host ""
    Write-Host ("[{0}/{1}] {2}.{3} (bucket: {4})" -f $idx, $total, $row.Schema, $row.Object, $row.Bucket) -ForegroundColor White
    Write-Host ""

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $rc = -1
    try {
        & (Join-Path $harnessRoot "regen_one.ps1") `
            -Schema $row.Schema `
            -ObjectName $row.Object `
            -MaxAttempts $MaxAttempts `
            -WriterTimeoutSeconds $WriterTimeoutSeconds `
            -JudgeTimeoutSeconds $JudgeTimeoutSeconds
        $rc = $LASTEXITCODE
    } catch {
        Write-Host ("  -> regen_one threw: {0}" -f $_.Exception.Message) -ForegroundColor Red
        $rc = -1
    }
    $sw.Stop()
    $secs = [int]$sw.Elapsed.TotalSeconds

    Write-Host ("  -> regen_one exit={0}  ({1}s)" -f $rc, $secs) -ForegroundColor Gray

    $results += [pscustomobject]@{
        idx = $idx
        schema = $row.Schema
        object = $row.Object
        bucket = $row.Bucket
        exit_code = $rc
        seconds = $secs
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ("  All regen runs complete in {0}s" -f [int]$swAll.Elapsed.TotalSeconds) -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ---------- Compare phase (judge against current/, write per-object compare.md) ----------
if (-not $SkipCompare) {
    Write-Host "Running compare_one.py for every object..." -ForegroundColor Yellow
    & python (Join-Path $harnessRoot "compare_one.py") --all --manifest $ManifestPath
}

# ---------- Summary ----------
Write-Host "Running summarize.py..." -ForegroundColor Yellow
& python (Join-Path $harnessRoot "summarize.py") --manifest $ManifestPath --output-name $SummaryOutputName

$summaryPath = Join-Path $repoRoot ("audits\regen-sample\{0}.md" -f $SummaryOutputName)
if (Test-Path $summaryPath) {
    Write-Host ""
    Write-Host ("Summary written: {0}" -f $summaryPath) -ForegroundColor Green
}

Write-Host ""
exit 0
