# Get-NextBatch.ps1 -- shared batch picker for the wiki documentation loops.
#
# Why this exists:
#   The agent used to spend 100-220s of bash/grep at the start of every batch
#   discovering pending objects. That work is deterministic and pure I/O --
#   move it to PowerShell, run it in <2s, and inject the resulting list as a
#   "BATCH ASSIGNMENT" block in the prompt. The agent then skips the discovery
#   phase entirely and proceeds straight to Phase 1 of object #1.
#
# Inputs:
#   -SchemaName    Schema to pick for (e.g. "BI_DB_dbo", "eMoney_dbo")
#   -BatchSize     Default batch size (default = 8). Heavy-table caps may apply.
#   -RepoRoot      Databricks_Knowledge repo root
#   -DataPlatformRoot  DataPlatform repo root (for SSDT DDLs)
#
# Output:
#   Hashtable: @{ Empty=$bool; Count=$int; Picked=$list; HeavyCap=$bool; Block=$string }

function Get-NextBatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string] $SchemaName,
        [int]    $BatchSize        = 8,
        [string] $RepoRoot         = "C:\Users\guyman\Documents\github\Databricks_Knowledge",
        [string] $DataPlatformRoot = "C:\Users\guyman\Documents\github\DataPlatform",
        [switch] $AlterScopeOnly,
        [string] $AlterScopeJson   = ""
    )

    $configPath  = Join-Path $RepoRoot ".specify\Configs\dwh-semantic-doc-config.json"
    $opsdbPath   = Join-Path $RepoRoot ".specify\Configs\opsdb-objects-status.json"
    $wikiTables  = Join-Path $RepoRoot "knowledge\synapse\Wiki\$SchemaName\Tables"
    $wikiViews   = Join-Path $RepoRoot "knowledge\synapse\Wiki\$SchemaName\Views"
    $ssdtTables  = Join-Path $DataPlatformRoot "SynapseSQLPool1\sql_dp_prod_we\$SchemaName\Tables"

    if (-not (Test-Path $configPath)) { throw "Config not found: $configPath" }
    if (-not (Test-Path $ssdtTables)) { throw "SSDT path not found: $ssdtTables" }

    # ---- Schema-level blacklist (early exit) -----------------------------
    # If the requested schema is in object_blacklist.schema_blacklist, return
    # an empty batch immediately. Used for permanently-out-of-scope schemas
    # like DWH_staging where per-table inspection is wasted work.
    $earlyConfig = Get-Content $configPath -Raw | ConvertFrom-Json
    $schemaBlacklist = @($earlyConfig.databases.synapse_dwh.object_blacklist.schema_blacklist)
    foreach ($sb in $schemaBlacklist) {
        if ($sb.schema -eq $SchemaName) {
            Write-Warning "Schema '$SchemaName' is in object_blacklist.schema_blacklist (reason: $($sb.reason)). Returning empty batch."
            return @{ Empty = $true; Count = 0; Picked = @(); HeavyCap = $false; Block = "" }
        }
    }

    # ---- Load ALTER scope (optional gate) --------------------------------
    # When -AlterScopeOnly is set, only objects that are in the lake-bound
    # ALTER scope (mapped to UC OR downstream of mapped) are eligible. This
    # shifts the wiki build to match the ALTER scope so we stop spending
    # tokens on objects that will never produce ALTER description files.
    $scopeSet = $null
    if ($AlterScopeOnly) {
        if (-not $AlterScopeJson) {
            $AlterScopeJson = Join-Path $RepoRoot "audits\regen-sample\_alter_scope.json"
        }
        if (-not (Test-Path $AlterScopeJson)) {
            throw "AlterScopeOnly requested but scope file not found: $AlterScopeJson (run tools/regen-harness/build_alter_scope.py)"
        }
        $scopeData = Get-Content $AlterScopeJson -Raw | ConvertFrom-Json
        $scopeSet = New-Object System.Collections.Generic.HashSet[string]
        foreach ($r in $scopeData.in_scope) {
            if ($r.schema -eq $SchemaName) {
                [void]$scopeSet.Add($r.name.ToLowerInvariant())
            }
        }
        if ($scopeSet.Count -eq 0) {
            Write-Warning "AlterScopeOnly: no in-scope objects found for schema '$SchemaName' in $AlterScopeJson."
        }
    }

    # ---- Load blacklist ---------------------------------------------------
    # Three sources unioned: (a) central config explicit + patterns,
    # (b) per-schema _blacklist.json (DWH_dbo style), (c) per-schema
    # _index.md "Blacklisted" tables (eMoney/EXW style).
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $bl = $config.databases.synapse_dwh.object_blacklist

    $explicitSet = New-Object System.Collections.Generic.HashSet[string]
    foreach ($entry in @($bl.explicit_blacklist)) {
        if ($entry.schema -eq $SchemaName) {
            [void]$explicitSet.Add($entry.table.ToLowerInvariant())
        }
    }
    $namePatterns = @()
    foreach ($p in @($bl.name_patterns)) { $namePatterns += $p.pattern }

    # (b) per-schema _blacklist.json (curated category-tagged list)
    $schemaBlacklistJson = Join-Path $RepoRoot "knowledge\synapse\Wiki\$SchemaName\_blacklist.json"
    if (Test-Path $schemaBlacklistJson) {
        try {
            $schemaBl = Get-Content $schemaBlacklistJson -Raw | ConvertFrom-Json
            foreach ($entry in @($schemaBl.blacklist)) {
                if ($entry.object) {
                    [void]$explicitSet.Add($entry.object.ToLowerInvariant())
                }
            }
        } catch {
            Write-Warning "Failed to parse $schemaBlacklistJson : $_"
        }
    }

    # (c) per-schema _index.md "Blacklisted" sections (table rows in any
    # heading whose text contains "Blacklist", PLUS all deeper nested
    # subheadings under it). Captures the eMoney pattern where the top-level
    # is "### Tables -- Blacklisted" and child sub-sub-headings group by
    # category (FiatDwhDB mirrors, ETL staging, Temp/backup/test/dup).
    $schemaIndex = Join-Path $RepoRoot "knowledge\synapse\Wiki\$SchemaName\_index.md"
    if (Test-Path $schemaIndex) {
        try {
            $lines = Get-Content $schemaIndex -ErrorAction SilentlyContinue
            $blacklistDepth = 0   # heading depth at which we entered blacklist scope (0 = not in scope)
            foreach ($ln in $lines) {
                if ($ln -match '^(#{1,6})\s+(.+)$') {
                    $depth   = $Matches[1].Length
                    $heading = $Matches[2]
                    if ($blacklistDepth -gt 0 -and $depth -le $blacklistDepth -and ($heading -notmatch '(?i)blacklist')) {
                        # Hit a heading at same/higher level that is NOT a blacklist section -> exit scope
                        $blacklistDepth = 0
                    }
                    if ($heading -match '(?i)blacklist' -and $blacklistDepth -eq 0) {
                        $blacklistDepth = $depth
                    }
                    continue
                }
                if ($blacklistDepth -eq 0) { continue }
                # Match markdown table rows: | Object | reason |
                # Skip header and separator rows.
                if ($ln -match '^\|\s*([^\|\s][^\|]*?)\s*\|') {
                    $cell = $Matches[1].Trim()
                    if ($cell -eq 'Object' -or $cell -match '^[-:|\s]+$') { continue }
                    # Strip wrapping markdown: ~~name~~, [name](...), `name`, schema. prefix
                    $cell = $cell -replace '~~','' -replace '`',''
                    if ($cell -match '^\[([^\]]+)\]') { $cell = $Matches[1] }
                    if ($cell -like "$SchemaName.*") { $cell = $cell.Substring($SchemaName.Length + 1) }
                    if ($cell) { [void]$explicitSet.Add($cell.ToLowerInvariant()) }
                }
            }
        } catch {
            Write-Warning "Failed to parse blacklist sections in $schemaIndex : $_"
        }
    }

    # ---- Load OpsDB priority map -----------------------------------------
    $priorityMap = @{}
    $procMap     = @{}
    if (Test-Path $opsdbPath) {
        $opsdb = Get-Content $opsdbPath -Raw | ConvertFrom-Json
        foreach ($row in $opsdb) {
            if ($row.TableName -like "$SchemaName.*") {
                $obj = $row.TableName.Substring($SchemaName.Length + 1)
                if (-not $priorityMap.ContainsKey($obj)) {
                    $priorityMap[$obj] = [int]$row.Priority
                    $procMap[$obj]     = $row.ProcedureName
                }
            }
        }
    }

    # ---- Enumerate SSDT tables -------------------------------------------
    $allTables = Get-ChildItem -Path (Join-Path $ssdtTables "*.sql") -ErrorAction SilentlyContinue |
                 ForEach-Object {
                     $name = $_.BaseName
                     if ($name -like "$SchemaName.*") { $name.Substring($SchemaName.Length + 1) } else { $name }
                 }

    # ---- Filter ----------------------------------------------------------
    $candidates = New-Object System.Collections.Generic.List[psobject]
    foreach ($t in $allTables) {
        $wikiFile     = Join-Path $wikiTables "$t.md"
        $wikiViewFile = Join-Path $wikiViews  "$t.md"
        # An object is "documented" if a wiki exists EITHER under Tables/ or
        # Views/. Some SSDT folders have stale Tables/ entries for objects
        # that are actually views in Synapse (the live wiki lives under Views/).
        if ((Test-Path $wikiFile) -or (Test-Path $wikiViewFile)) { continue }

        if ($explicitSet.Contains($t.ToLowerInvariant())) { continue }

        $skipped = $false
        foreach ($pat in $namePatterns) {
            if ($t -like $pat) { $skipped = $true; break }
        }
        if ($skipped) { continue }

        # ALTER scope gate: drop candidates that are not in the lake-bound
        # scope (mapped to UC or downstream of mapped). Only active when
        # -AlterScopeOnly was supplied.
        if ($scopeSet -ne $null) {
            if (-not $scopeSet.Contains($t.ToLowerInvariant())) { continue }
        }

        $priority = if ($priorityMap.ContainsKey($t)) { $priorityMap[$t] } else { 99 }
        $writerSp = if ($procMap.ContainsKey($t))     { $procMap[$t]     } else { $null }

        $candidates.Add([pscustomobject]@{
            Name     = $t
            Priority = $priority
            WriterSP = $writerSp
        }) | Out-Null
    }

    if ($candidates.Count -eq 0) {
        return @{ Empty = $true; Count = 0; Picked = @(); HeavyCap = $false; Block = "" }
    }

    # ---- Sort: priority asc, then alphabetical ---------------------------
    # @(...) wrap is REQUIRED: when $candidates has exactly 1 item, Sort-Object
    # returns a bare PSCustomObject (not a list). PSCustomObject.Count is $null,
    # which silently makes the for-loops below never iterate, so a single-item
    # backlog returns 0 picked. @(...) forces a real array with .Count == 1.
    $sorted = @($candidates | Sort-Object Priority, Name)

    # ---- Compute column count for top (BatchSize+5) candidates ----------
    $colCounts = @{}
    $inspectN = [Math]::Min($sorted.Count, $BatchSize + 5)
    for ($i = 0; $i -lt $inspectN; $i++) {
        $name = $sorted[$i].Name
        $sqlFile = Join-Path $ssdtTables "$SchemaName.$name.sql"
        if (Test-Path $sqlFile) {
            $body = Get-Content $sqlFile -Raw -ErrorAction SilentlyContinue
            if ($body) {
                # Count column lines: leading whitespace + [Identifier] + space + [type] or word-type.
                # SSDT format: `\t[ColName] [int] NOT NULL,` or `\t[ColName] [varchar](22) NULL,`.
                $matchList = [regex]::Matches($body, '(?im)^\s+\[[A-Za-z0-9_]+\]\s+(\[[A-Za-z]|[A-Za-z]+\s)')
                $colCounts[$name] = $matchList.Count
            }
        }
    }

    # ---- Pick the batch with column-weight rules ------------------------
    $picked    = New-Object System.Collections.Generic.List[psobject]
    $heavyCap  = $false

    for ($i = 0; $i -lt $sorted.Count; $i++) {
        $cand = $sorted[$i]
        $cols = if ($colCounts.ContainsKey($cand.Name)) { $colCounts[$cand.Name] } else { 0 }

        if ($cols -gt 50) { $heavyCap = $true }

        $effectiveSize = if ($heavyCap) { 4 } else { $BatchSize }

        if ($picked.Count -ge $effectiveSize) { break }

        $picked.Add([pscustomobject]@{
            Name     = $cand.Name
            Priority = $cand.Priority
            WriterSP = $cand.WriterSP
            Columns  = $cols
        }) | Out-Null
    }

    # ---- Build BATCH ASSIGNMENT prompt block -----------------------------
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## BATCH ASSIGNMENT (pre-picked by orchestrator -- DO NOT re-discover)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("The next batch has been pre-selected for you. **Skip the 'Plan batch' discovery phase**. Read ``_index.md`` and ``_batch_context.json`` for context (they are still required), but use the object list below as your batch instead of running OpsDB / blacklist / priority checks yourself.")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Schema: ``$SchemaName``")
    [void]$sb.AppendLine("Batch size: $($picked.Count) (orchestrator-picked, weighted)")
    if ($heavyCap) { [void]$sb.AppendLine("Heavy-cap applied: yes (one candidate has > 50 columns; size limited to 4)") }
    if ($scopeSet -ne $null) {
        [void]$sb.AppendLine("ALTER scope filter: ON ($($scopeSet.Count) in-scope objects available in this schema)")
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| # | Object | Priority | Writer SP | Columns |")
    [void]$sb.AppendLine("|---|--------|----------|-----------|---------|")
    for ($i = 0; $i -lt $picked.Count; $i++) {
        $p = $picked[$i]
        $sp = if ($p.WriterSP) { "``$($p.WriterSP)``" } else { "(none in OpsDB)" }
        [void]$sb.AppendLine("| $($i+1) | ``$($p.Name)`` | $($p.Priority) | $sp | $($p.Columns) |")
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Process them in the order shown. Apply the standard execution card (Phases 1 -> 11 -> 16) to each.")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")

    return @{
        Empty    = $false
        Count    = $picked.Count
        Picked   = $picked
        HeavyCap = $heavyCap
        Block    = $sb.ToString()
    }
}
