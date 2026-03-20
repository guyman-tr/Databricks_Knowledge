<#
.SYNOPSIS
    Validates a DWH wiki .md file against the Phase 11 spec.
.DESCRIPTION
    Deterministic checks that MUST pass before a wiki doc is considered complete.
    Run after writing each .md file. Exit code 0 = PASS, 1 = FAIL.
.PARAMETER Path
    Path to the wiki .md file to validate (e.g. Tables/Dim_Customer.md).
.PARAMETER ObjectType
    Optional. "Table" or "View". Auto-detected from the file header if omitted.
.EXAMPLE
    .\.cursor\scripts\validate-wiki.ps1 -Path "knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md"
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [ValidateSet("Table", "View")]
    [string]$ObjectType = ""
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Path)) {
    Write-Host "ERROR: File not found: $Path" -ForegroundColor Red
    exit 1
}

$content = Get-Content $Path -Encoding UTF8
$raw = $content -join "`n"
$fileName = Split-Path $Path -Leaf
$baseName = $fileName -replace '\.md$', ''
$dir = Split-Path $Path -Parent

$totalChecks = 0
$failedChecks = 0
$failDetails = @()

Write-Host ""
Write-Host "VALIDATE: $fileName" -ForegroundColor Cyan

# --- Auto-detect object type if not provided ---
if (-not $ObjectType) {
    if ($raw -match '\*\*Object Type\*\*\s*\|\s*(Table|View)') {
        $ObjectType = $Matches[1]
    }
    elseif ($dir -match 'Tables') {
        $ObjectType = "Table"
    }
    elseif ($dir -match 'Views') {
        $ObjectType = "View"
    }
    else {
        $ObjectType = "Table"
    }
}

# ============================================================
# CHECK 1: 8 mandatory section headers
# ============================================================
$totalChecks++
$requiredSections = @(
    '## 1. Business Meaning',
    '## 2. Business Logic',
    '## 3. Query Advisory',
    '## 4. Elements',
    '## 5. Lineage',
    '## 6. Relationships',
    '## 7. Sample Queries',
    '## 8. Atlassian Knowledge Sources'
)

$missingSections = @()
foreach ($section in $requiredSections) {
    $found = $false
    foreach ($line in $content) {
        if ($line.Trim() -eq $section) {
            $found = $true
            break
        }
    }
    if (-not $found) {
        $missingSections += $section
    }
}

if ($missingSections.Count -eq 0) {
    Write-Host "  [PASS] 8 sections present" -ForegroundColor Green
}
else {
    $failedChecks++
    Write-Host "  [FAIL] Sections: $($requiredSections.Count - $missingSections.Count)/$($requiredSections.Count) present" -ForegroundColor Red
    foreach ($s in $missingSections) {
        Write-Host "         Missing: $s" -ForegroundColor Red
    }
    $failDetails += "Missing sections: $($missingSections -join ', ')"
}

# ============================================================
# CHECK 2: Tier suffix on every element row
# ============================================================
$totalChecks++

$inElements = $false
$pastElements = $false
$elementRows = @()
$elementRowsMissing = @()

foreach ($line in $content) {
    if ($line.Trim() -eq '## 4. Elements') {
        $inElements = $true
        continue
    }
    if ($inElements -and $line.Trim() -match '^## \d+\.') {
        $pastElements = $true
        $inElements = $false
        continue
    }
    if ($inElements -and $line -match '^\|\s*(\d+)\s*\|') {
        $rowNum = $Matches[1]
        $elementRows += $rowNum
        if ($line -notmatch '\(Tier\s') {
            $colName = ""
            if ($line -match '^\|\s*\d+\s*\|\s*([^|]+?)\s*\|') {
                $colName = $Matches[1].Trim()
            }
            $elementRowsMissing += "#$rowNum $colName"
        }
    }
}

$totalElements = $elementRows.Count
$passingElements = $totalElements - $elementRowsMissing.Count

if ($totalElements -eq 0) {
    $failedChecks++
    Write-Host "  [FAIL] Tier suffix: No element rows found in ## 4. Elements" -ForegroundColor Red
    $failDetails += "No element rows found"
}
elseif ($elementRowsMissing.Count -eq 0) {
    Write-Host "  [PASS] Tier suffix: $totalElements/$totalElements rows have (Tier N) suffix" -ForegroundColor Green
}
else {
    $failedChecks++
    Write-Host "  [FAIL] Tier suffix: $passingElements/$totalElements rows have suffix ($($elementRowsMissing.Count) MISSING)" -ForegroundColor Red
    $preview = $elementRowsMissing | Select-Object -First 10
    Write-Host "         Missing: $($preview -join ', ')" -ForegroundColor Red
    if ($elementRowsMissing.Count -gt 10) {
        Write-Host "         ... and $($elementRowsMissing.Count - 10) more" -ForegroundColor Red
    }
    $failDetails += "Tier suffix missing on $($elementRowsMissing.Count) elements"
}

# ============================================================
# CHECK 3: Minimum line count
# ============================================================
$totalChecks++
$lineCount = $content.Count
$minLines = if ($ObjectType -eq "View") { 80 } else { 100 }

if ($lineCount -ge $minLines) {
    Write-Host "  [PASS] Line count: $lineCount (min $minLines for $ObjectType)" -ForegroundColor Green
}
else {
    $failedChecks++
    Write-Host "  [FAIL] Line count: $lineCount (min $minLines for $ObjectType)" -ForegroundColor Red
    $failDetails += "Line count $lineCount below minimum $minLines"
}

# ============================================================
# CHECK 4: 3-file check (.md + .review-needed.md + .lineage.md)
# ============================================================
$totalChecks++
$reviewPath = Join-Path $dir "$baseName.review-needed.md"
$lineagePath = Join-Path $dir "$baseName.lineage.md"
$missingFiles = @()

if (-not (Test-Path $reviewPath)) { $missingFiles += "$baseName.review-needed.md" }
if (-not (Test-Path $lineagePath)) { $missingFiles += "$baseName.lineage.md" }

if ($missingFiles.Count -eq 0) {
    Write-Host "  [PASS] 3 files exist (.md + .review-needed.md + .lineage.md)" -ForegroundColor Green
}
else {
    $failedChecks++
    Write-Host "  [FAIL] Missing companion files: $($missingFiles -join ', ')" -ForegroundColor Red
    $failDetails += "Missing files: $($missingFiles -join ', ')"
}

# ============================================================
# CHECK 5: Quality footer
# ============================================================
$totalChecks++
$hasQuality = $false
$tail = $content | Select-Object -Last 10
foreach ($line in $tail) {
    if ($line -match 'Quality:\s*\d') {
        $hasQuality = $true
        break
    }
}

if ($hasQuality) {
    Write-Host "  [PASS] Quality footer present" -ForegroundColor Green
}
else {
    $failedChecks++
    Write-Host "  [FAIL] Quality footer missing (no 'Quality: N.N' in last 10 lines)" -ForegroundColor Red
    $failDetails += "Quality footer missing"
}

# ============================================================
# RESULT
# ============================================================
Write-Host ""
if ($failedChecks -eq 0) {
    Write-Host "RESULT: PASS ($totalChecks/$totalChecks checks passed)" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "RESULT: FAIL ($failedChecks check(s) failed)" -ForegroundColor Red
    foreach ($d in $failDetails) {
        Write-Host "  - $d" -ForegroundColor Red
    }
    exit 1
}
