param(
    [Parameter(Mandatory=$true)]
    [string]$Path
)

# Semantic validation: cross-references DWH wiki tier assignments against upstream DB_Schema wikis.
# Returns exit code 0 (PASS), 1 (FAIL), or 2 (WARNING).
# Run AFTER validate-wiki.ps1 (structural check) — this checks SEMANTIC correctness.

$dbSchemaBase = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) '..\DB_Schema\etoro\Wiki'
if (-not (Test-Path $dbSchemaBase)) {
    $dbSchemaBase = 'C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki'
}

if (-not (Test-Path $Path)) {
    Write-Host "ERROR: File not found: $Path"
    exit 1
}

$fileName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
$content = Get-Content $Path -Encoding UTF8

# --- Extract Production Source from properties table ---
$prodSource = $null
$prodSources = @()
foreach ($line in $content) {
    if ($line -match '\*\*Production Source[s]?\*\*\s*\|\s*(.+)\|') {
        $raw = $Matches[1].Trim().Trim('`').Trim()
        # Handle 3-part (etoro.Schema.Table) or 2-part (Schema.Table) names
        $candidates = [regex]::Matches($raw, '(?:etoro\.)?([A-Za-z_]+\.[A-Za-z_]+)')
        foreach ($m in $candidates) {
            $prodSources += $m.Groups[1].Value
        }
        if ($prodSources.Count -gt 0) { $prodSource = $prodSources[0] }
        break
    }
}

# --- Extract DWH columns and their tier assignments from Elements table ---
$dwhColumns = @{}
$inElements = $false
foreach ($line in $content) {
    if ($line -match '^## 4\. Elements') { $inElements = $true; continue }
    if ($inElements -and $line -match '^## \d') { break }
    if ($inElements -and $line -match '^\|\s*(\d+)\s*\|\s*([A-Za-z0-9_]+)\s*\|') {
        $colName = $Matches[2]
        $tier = 0
        if ($line -match '\(Tier\s+(\d+)') { $tier = [int]$Matches[1] }
        $dwhColumns[$colName] = $tier
    }
}

$totalCols = $dwhColumns.Count
$tier1Count = ($dwhColumns.Values | Where-Object { $_ -eq 1 }).Count
$tier2Count = ($dwhColumns.Values | Where-Object { $_ -eq 2 }).Count

Write-Host ""
Write-Host "SEMANTIC VALIDATE: $fileName"
Write-Host "  Production Source: $(if ($prodSource) { $prodSource } else { 'NOT FOUND' })"
Write-Host "  DWH columns: $totalCols (T1=$tier1Count, T2=$tier2Count)"

# --- Find and read upstream wiki(s) ---
$upstreamMatches = 0
$upstreamFiles = @()

if ($prodSource -and $prodSource -ne 'Derived' -and $prodSource -ne 'Multiple sources') {
    $parts = $prodSource -split '\.'
    if ($parts.Count -eq 2) {
        $schema = $parts[0]
        $table = $parts[1]

        # Search tables
        $tablePath = Join-Path $dbSchemaBase "$schema\Tables\$schema.$table.md"
        if (Test-Path $tablePath) { $upstreamFiles += $tablePath }

        # Search views
        $viewPath = Join-Path $dbSchemaBase "$schema\Views\$schema.$table.md"
        if (Test-Path $viewPath) { $upstreamFiles += $viewPath }

        # Search related views in same schema (staging views that add computed columns)
        $viewDir = Join-Path $dbSchemaBase "$schema\Views"
        if (Test-Path $viewDir) {
            Get-ChildItem $viewDir -Filter '*.md' | ForEach-Object {
                if ($_.FullName -notin $upstreamFiles) {
                    $viewContent = Get-Content $_.FullName -Encoding UTF8 -TotalCount 100
                    $hasMatchingCols = $false
                    foreach ($vc in $viewContent) {
                        if ($vc -match '^\|\s*\d+\s*\|\s*([A-Za-z0-9_]+)\s*\|') {
                            $vcName = $Matches[1]
                            if ($dwhColumns.ContainsKey($vcName) -and $dwhColumns[$vcName] -ne 1) {
                                $hasMatchingCols = $true
                                break
                            }
                        }
                    }
                    if ($hasMatchingCols) { $upstreamFiles += $_.FullName }
                }
            }
        }
    }
}

# Also check the lineage file for additional source tables
$lineagePath = $Path -replace '\.md$', '.lineage.md'
$lineagePyPath = $Path -replace '\.md$', '.lineage.py'
$lineageSourceTables = @()

foreach ($lPath in @($lineagePath, $lineagePyPath)) {
    if (Test-Path $lPath) {
        $lContent = Get-Content $lPath -Encoding UTF8
        foreach ($ll in $lContent) {
            # Python dict: "Trade.PositionTbl": [
            if ($ll -match '"([A-Za-z]+\.[A-Za-z_]+)":\s*\[') {
                $lineageSourceTables += $Matches[1]
            }
            # Markdown table: | column | `Trade.PositionTbl` | ...
            if ($ll -match '\|\s*[A-Za-z_]+\s*\|\s*`?([A-Za-z]+\.[A-Za-z_]+)`?\s*\|') {
                $srcTable = $Matches[1]
                if ($srcTable -notmatch '^DWH|^SP_|^Ext_|^Wiki|^Source|^Source ') {
                    $lineageSourceTables += $srcTable
                }
            }
            # Freetext: Customer.CustomerStatic appearing as Schema.Table
            # Match Primary Sources / Source Table lines
            if ($ll -match 'Primary Source|Source Table') {
                $candidates = [regex]::Matches($ll, '(?<![`/\\])([A-Z][a-zA-Z]+\.[A-Z][a-zA-Z_]+)(?!\.md)')
                foreach ($m in $candidates) {
                    $val = $m.Groups[1].Value
                    if ($val -notmatch '^DWH|^SP_|^Ext_|^Wiki|^Source\.|^DB_') {
                        $lineageSourceTables += $val
                    }
                }
            }
            # Freetext lineage chains: Customer.CustomerStatic ───> ...
            if ($ll -match '([A-Z][a-zA-Z]+\.[A-Z][a-zA-Z_]+)\s+[-]+') {
                $val = $Matches[1]
                if ($val -notmatch '^DWH|^SP_|^Ext_|^Wiki') {
                    $lineageSourceTables += $val
                }
            }
        }
    }
}

$lineageSourceTables = $lineageSourceTables | Sort-Object -Unique
foreach ($srcTable in $lineageSourceTables) {
    $stParts = $srcTable -split '\.'
    if ($stParts.Count -eq 2) {
        $stSchema = $stParts[0]
        $stTable = $stParts[1]
        $stPath = Join-Path $dbSchemaBase "$stSchema\Tables\$stSchema.$stTable.md"
        if ((Test-Path $stPath) -and $stPath -notin $upstreamFiles) {
            $upstreamFiles += $stPath
        }
        $svPath = Join-Path $dbSchemaBase "$stSchema\Views\$stSchema.$stTable.md"
        if ((Test-Path $svPath) -and $svPath -notin $upstreamFiles) {
            $upstreamFiles += $svPath
        }
    }
}

# --- Extract upstream column names from all upstream wikis ---
$upstreamColumns = @{}
foreach ($uf in $upstreamFiles) {
    $ufName = [System.IO.Path]::GetFileNameWithoutExtension($uf)
    $ufContent = Get-Content $uf -Encoding UTF8
    $inEl = $false
    foreach ($ul in $ufContent) {
        if ($ul -match '^## [34]\. (Elements|Data Overview)') { $inEl = $true; continue }
        if ($inEl -and $ul -match '^## \d') { break }
        if ($inEl -and $ul -match '^\|\s*\d+\s*\|\s*([A-Za-z0-9_]+)\s*\|') {
            $ucName = $Matches[1]
            if (-not $upstreamColumns.ContainsKey($ucName)) {
                $upstreamColumns[$ucName] = $ufName
            }
        }
    }
}

Write-Host "  Upstream wikis found: $($upstreamFiles.Count)"
foreach ($uf in $upstreamFiles) {
    Write-Host "    - $([System.IO.Path]::GetFileName($uf))"
}
Write-Host "  Upstream columns documented: $($upstreamColumns.Count)"

# --- Cross-reference: which DWH columns have upstream matches? ---
$matchable = @{}
foreach ($col in $dwhColumns.Keys) {
    if ($upstreamColumns.ContainsKey($col)) {
        $matchable[$col] = $upstreamColumns[$col]
    }
}

$matchCount = $matchable.Count
Write-Host "  DWH columns with upstream wiki match: $matchCount"

# --- Check: How many matchable columns actually got Tier 1? ---
$matchedAndTier1 = 0
$matchedButNotTier1 = [System.Collections.ArrayList]@()
foreach ($col in $matchable.Keys) {
    if ($dwhColumns[$col] -eq 1) {
        $matchedAndTier1++
    } else {
        [void]$matchedButNotTier1.Add("    MISS: $col (Tier $($dwhColumns[$col])) <- upstream: $($matchable[$col])")
    }
}

$exitCode = 0
$result = 'PASS'

if ($matchCount -gt 10 -and $matchedAndTier1 -eq 0) {
    Write-Host ""
    Write-Host "  [FAIL] ZERO Tier 1 columns despite $matchCount matchable upstream columns!"
    Write-Host "  The upstream wiki was found and has matching columns, but NONE got Tier 1."
    Write-Host "  This means Phase 10.5 (Upstream Wiki Bridge) was skipped or ignored."
    $exitCode = 1
    $result = 'FAIL'
} elseif ($matchCount -gt 0 -and $matchedAndTier1 -lt [Math]::Floor($matchCount * 0.4)) {
    Write-Host ""
    Write-Host "  [WARN] Only $matchedAndTier1/$matchCount matchable columns got Tier 1 (<40%)"
    Write-Host "  Check if columns were incorrectly assigned Tier 2 when upstream wiki exists."
    $exitCode = 2
    $result = 'WARNING'
} else {
    Write-Host ""
    Write-Host "  [PASS] Tier 1 coverage: $matchedAndTier1/$matchCount matchable columns"
}

if ($matchedButNotTier1.Count -gt 0 -and $matchedButNotTier1.Count -le 20) {
    Write-Host ""
    Write-Host "  Columns with upstream wiki match but NOT Tier 1:"
    $matchedButNotTier1 | ForEach-Object { Write-Host $_ }
}
if ($matchedButNotTier1.Count -gt 20) {
    Write-Host ""
    Write-Host "  $($matchedButNotTier1.Count) columns have upstream match but NOT Tier 1 (showing first 15):"
    $matchedButNotTier1 | Select-Object -First 15 | ForEach-Object { Write-Host $_ }
    Write-Host "    ... and $($matchedButNotTier1.Count - 15) more"
}

Write-Host ""
Write-Host "SEMANTIC RESULT: $result"
Write-Host ""
exit $exitCode
