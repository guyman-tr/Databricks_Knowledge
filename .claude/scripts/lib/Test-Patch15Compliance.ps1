# Test-Patch15Compliance.ps1 -- per-iteration guardrail for Patch 1.5 (Tier 1
# inheritance for dim-lookup passthroughs) and Phase 11's UPSTREAM SEARCH LOG
# self-check. Catches the failure mode discovered on 2026-04-27:
#
#   Symptom: agent's .lineage.md correctly marks columns as "passthrough" from
#            an upstream Synapse wiki that exists, but the .md file tags every
#            such column Tier 2 and skips the UPSTREAM SEARCH LOG block.
#
#   Verdict: the agent *knows* it's a passthrough, *knows* the upstream wiki
#            exists, and still defaults to Tier 2 -- meaning Phase 11's Pre-Read
#            step (Patch 1.5) was bypassed for this object.
#
# This guardrail runs after each batch, scans wikis written in the iteration
# window, flags violators, and appends them to a must-fix list that the
# post-run wiki auditor consumes once the big run finishes.
#
# Returns: array of [PSCustomObject] with shape:
#   { Schema, Object, WikiPath, PassthroughEligible, PassthroughInherited,
#     MissingSearchLog, IsViolation, Reason }

function Test-Patch15Compliance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string]   $SchemaName,
        [Parameter(Mandatory=$true)] [datetime] $Since,
        [string] $RepoRoot = "C:\Users\guyman\Documents\github\Databricks_Knowledge"
    )

    $wikiRoot   = Join-Path $RepoRoot "knowledge\synapse\Wiki"
    $schemaRoot = Join-Path $wikiRoot $SchemaName
    if (-not (Test-Path $schemaRoot)) { return @() }

    # ── Discover wikis written this iteration ────────────────────────────────
    $candidates = @()
    foreach ($sub in @("Tables","Views")) {
        $folder = Join-Path $schemaRoot $sub
        if (-not (Test-Path $folder)) { continue }
        $candidates += Get-ChildItem $folder -Filter "*.md" -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.LastWriteTime -gt $Since -and
                $_.Name -notlike "*.lineage.md" -and
                $_.Name -notlike "*.review-needed.md" -and
                -not $_.Name.StartsWith("_")
            }
    }
    if (-not $candidates) { return @() }

    # ── Cache for "does this schema have a wiki for this table?" lookups ─────
    # Key: "{schema}|{table}" lower-cased -> bool
    $wikiExistsCache = @{}
    function Test-UpstreamWikiExists {
        param([string]$Schema, [string]$Table)
        $key = ("{0}|{1}" -f $Schema.ToLower(), $Table.ToLower())
        if ($wikiExistsCache.ContainsKey($key)) { return $wikiExistsCache[$key] }
        $found = $false
        foreach ($sub in @("Tables","Views","Functions")) {
            $p = Join-Path $wikiRoot ("{0}\{1}\{2}.md" -f $Schema, $sub, $Table)
            if (Test-Path $p) { $found = $true; break }
        }
        $wikiExistsCache[$key] = $found
        return $found
    }

    # ── Resolve the upstream schema for a bare or qualified table name ───────
    # Returns the schema that hosts the wiki, or $null if no wiki exists anywhere.
    function Resolve-UpstreamSchema {
        param([string]$RawTable, [string]$CurrentSchema)
        # RawTable might be "DWH_dbo.Dim_Country" or "Dim_Country" or
        # "BI_DB_dbo.BI_DB_Foo" or even "DWH_dbo.Dim_Customer / Dim_Country"
        # (multi-source rows). Take only the first comma/slash-free chunk.
        $first = ($RawTable -split '[,/]')[0].Trim()
        if ($first -match '^([A-Za-z_][\w]*)\.([A-Za-z_][\w]*)$') {
            $schema = $Matches[1]
            $table  = $Matches[2]
            if (Test-UpstreamWikiExists -Schema $schema -Table $table) { return @{ Schema=$schema; Table=$table } }
            return $null
        }
        # Bare table name -- try DWH_dbo, then current schema, then a few common ones.
        foreach ($schema in @("DWH_dbo", $CurrentSchema, "BI_DB_dbo", "eMoney_dbo", "EXW_dbo", "Dealing_dbo")) {
            if (-not $schema) { continue }
            if (Test-UpstreamWikiExists -Schema $schema -Table $first) {
                return @{ Schema=$schema; Table=$first }
            }
        }
        return $null
    }

    $results = @()

    foreach ($wiki in $candidates) {
        $objectName = $wiki.BaseName
        $lineagePath = Join-Path $wiki.Directory.FullName ("{0}.lineage.md" -f $objectName)
        if (-not (Test-Path $lineagePath)) { continue }  # No lineage → can't judge

        $wikiText    = Get-Content $wiki.FullName -Raw -ErrorAction SilentlyContinue
        $lineageText = Get-Content $lineagePath  -Raw -ErrorAction SilentlyContinue
        if (-not $wikiText -or -not $lineageText) { continue }

        # Locate the Column Lineage table in lineage and extract passthrough rows.
        # Format: | Col | SourceTable | SourceColumn | passthrough[ + extra notes] |
        $passthroughEligible = 0   # passthrough rows whose upstream wiki exists
        $passthroughInherited = 0  # of those, how many got Tier 1/4 inheritance in wiki
        $eligibleColumns = @()

        $inLineageTable = $false
        foreach ($line in ($lineageText -split "`r?`n")) {
            if (-not $inLineageTable -and $line -match '^\s*\|\s*(Synapse Column|DWH Column|Column)\s*\|') {
                $inLineageTable = $true
                continue
            }
            if (-not $inLineageTable) { continue }
            if ($line -match '^\s*\|\s*-{2,}') { continue }
            if ($line -notmatch '^\s*\|') {
                $inLineageTable = $false
                continue
            }
            $cells = $line -split '\|' | ForEach-Object { $_.Trim() }
            # cells[0] is empty (leading |), cells[-1] is empty (trailing |)
            if ($cells.Count -lt 5) { continue }
            $colName    = $cells[1]
            $srcTable   = $cells[2]
            $srcCol     = $cells[3]
            $transform  = $cells[4]

            if (-not $colName -or -not $srcTable) { continue }
            if ($colName -match '^[\u2014\-]+$' -or $srcTable -match '^[\u2014\-]+$' -or $srcTable.StartsWith('(')) { continue }

            # Only count rows whose Transform cell is a pure passthrough (or
            # passthrough-with-cast). Computed/aggregated/CASE rows are NOT
            # eligible for Tier 1 inheritance.
            $tlc = $transform.ToLower()
            $isPassthrough = ($tlc -eq 'passthrough') -or
                             ($tlc -match '^passthrough[\s;,(]') -or
                             ($tlc -match '^passthrough.*\(.*\)$') -or
                             ($tlc -match '^passthrough\b.*$' -and $tlc -notmatch 'computed|case|sum|count|avg|delta|join-enriched')

            if (-not $isPassthrough) { continue }

            $resolved = Resolve-UpstreamSchema -RawTable $srcTable -CurrentSchema $SchemaName
            if (-not $resolved) { continue }  # No wiki to inherit from → genuine Tier 2

            $passthroughEligible++
            $eligibleColumns += [PSCustomObject]@{
                Column      = $colName
                Source      = ("{0}.{1}" -f $resolved.Schema, $resolved.Table)
                SourceCol   = $srcCol
            }
        }

        if ($passthroughEligible -eq 0) {
            # Nothing to enforce on this object -- skip silently.
            continue
        }

        # Now check the wiki's element table for Tier 1 / Tier 4 tags on those columns.
        # We look for the column name appearing in an element row that ends with
        # "(Tier 1" or "(Tier 4" -- without restricting to the exact source, since
        # transitive origins (e.g., Tier 1 -- Trade.PositionTbl through a relay) are
        # legitimate per the rule.
        foreach ($ec in $eligibleColumns) {
            # Match "| N | ColumnName | type | nullable | desc...(Tier 1 ..."
            # Be tolerant of spacing and column-name punctuation.
            $escapedName = [regex]::Escape($ec.Column)
            $pattern = '^\s*\|\s*\d+\s*\|\s*' + $escapedName + '\s*\|.*?\(Tier\s*([14])\b'
            if ($wikiText -match $pattern) { $passthroughInherited++ }
        }

        $missingSearchLog = -not ($wikiText -match 'UPSTREAM SEARCH LOG')

        # Violation rule: at least one eligible passthrough was NOT inherited as Tier 1/4
        # AND the self-check log is missing. Either signal alone is suspicious; both
        # together is the "Patch 1.5 was bypassed" fingerprint.
        $missedInheritance = ($passthroughEligible - $passthroughInherited)
        $isViolation = ($missedInheritance -ge 2) -and $missingSearchLog

        if ($missedInheritance -ge 1 -or $missingSearchLog) {
            $reason = @()
            if ($missedInheritance -gt 0) {
                $reason += ("{0}/{1} eligible passthrough(s) tagged Tier 2/3/5 instead of Tier 1/4" -f `
                    $missedInheritance, $passthroughEligible)
            }
            if ($missingSearchLog) {
                $reason += "UPSTREAM SEARCH LOG block missing"
            }

            $results += [PSCustomObject]@{
                Schema                = $SchemaName
                Object                = $objectName
                WikiPath              = $wiki.FullName
                PassthroughEligible   = $passthroughEligible
                PassthroughInherited  = $passthroughInherited
                MissedInheritance     = $missedInheritance
                MissingSearchLog      = $missingSearchLog
                IsViolation           = $isViolation
                Reason                = ($reason -join '; ')
            }
        }
    }

    return $results
}

function Add-Patch15MustFix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] $Findings,
        [string] $RepoRoot = "C:\Users\guyman\Documents\github\Databricks_Knowledge"
    )

    if (-not $Findings -or $Findings.Count -eq 0) { return 0 }

    $auditsDir = Join-Path $RepoRoot "audits"
    if (-not (Test-Path $auditsDir)) { New-Item -ItemType Directory -Path $auditsDir | Out-Null }
    $listPath = Join-Path $auditsDir "patch15-must-fix.txt"

    # Read existing entries (if any) into a set, preserving prior comments.
    $existing = @{}
    if (Test-Path $listPath) {
        Get-Content $listPath -ErrorAction SilentlyContinue | ForEach-Object {
            $line = $_.Trim()
            if ($line -and -not $line.StartsWith('#')) {
                $existing[$line.ToLower()] = $true
            }
        }
    } else {
        $header = @(
            "# Patch 1.5 must-fix list - populated by the wiki batch loop's",
            "# per-iteration Patch15Compliance check. Format: one entry per",
            "# line as {Schema}/{ObjectName}. Consume with:",
            "#   python tools/wiki-auditor/audit.py --schema BI_DB_dbo \\",
            "#     --must-fix-list audits/patch15-must-fix.txt",
            ""
        ) -join "`r`n"
        [System.IO.File]::WriteAllText($listPath, $header, [System.Text.UTF8Encoding]::new($false))
    }

    $added = 0
    $sb = New-Object System.Text.StringBuilder
    foreach ($f in $Findings) {
        # Only add violators (severe enough to be worth a re-grade pass), not
        # mild signals. The auditor will catch milder cases on its own when run
        # against the broader corpus.
        if (-not $f.IsViolation) { continue }
        $entry = ("{0}/{1}" -f $f.Schema, $f.Object)
        if ($existing.ContainsKey($entry.ToLower())) { continue }
        [void]$sb.AppendLine($entry)
        $existing[$entry.ToLower()] = $true
        $added++
    }
    if ($added -gt 0) {
        # Append, don't overwrite. UTF-8 no BOM, LF for cross-tool friendliness.
        $stream = [System.IO.File]::Open($listPath, 'Append', 'Write', 'Read')
        try {
            $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($sb.ToString())
            $stream.Write($bytes, 0, $bytes.Length)
        } finally {
            $stream.Close()
        }
    }
    return $added
}
