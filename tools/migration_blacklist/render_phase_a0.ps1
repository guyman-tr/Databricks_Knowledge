param(
    [Parameter(Mandatory=$true)] [string] $McpOutputFile,
    [Parameter(Mandatory=$true)] [string] $CsvOut,
    [Parameter(Mandatory=$true)] [string] $MdOut
)

$ErrorActionPreference = 'Stop'

function Classify-ProcKind {
    param([string] $name)
    if ($name -match '^[A-Za-z_]+_(?:dbo|staging|Migration|watchlists|pagetracking)\.SP_') { return 'synapse_sp' }
    if ($name -match '^[A-Za-z_]+_(?:dbo|staging|Migration|watchlists|pagetracking)\.LP_') { return 'synapse_sp_lp' }
    if ($name -match '^[A-Za-z_]+_(?:dbo|staging|Migration|watchlists|pagetracking)\.Fact_') { return 'synapse_sp' }
    if ($name -match '^DE_dbo\.SP_CopyLakeToSynapse') { return 'copy_from_lake' }
    if ($name -match '^BI_DataBricks-') { return 'databricks_job' }
    if ($name -match '^Bronze/|^Silver/|^Gold/|^LP/|^analysis/|^internal-sources/|^config/|^BI_OUTPUT/|^Dictionary\.|^BI_COMPLIANCE/') { return 'lake_path' }
    if ($name -match ',') { return 'multi_ref' }
    if ($name -match '^DWH-') { return 'dwh_meta' }
    if ($name -match '^[A-Za-z_]+_(?:dbo|staging)\.') { return 'synapse_sp' }
    return 'other'
}

$lines = Get-Content -LiteralPath $McpOutputFile -Encoding UTF8
$rows = @()
$header = $null
foreach ($line in $lines) {
    if ($line -notmatch '^\|') { continue }
    if ($line -match '^\|\s*-+') { continue }
    $cells = ($line -replace '^\|','' -replace '\|$','') -split '\s*\|\s*'
    $cells = $cells | ForEach-Object { $_.Trim() }
    if ($null -eq $header) { $header = $cells; continue }
    if ($cells.Count -ne $header.Count) { continue }
    $row = [ordered]@{}
    for ($i=0; $i -lt $header.Count; $i++) { $row[$header[$i]] = $cells[$i] }
    $row['proc_kind'] = Classify-ProcKind -name $row['ProcedureName']
    $rows += [pscustomobject]$row
}

$rows | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath $CsvOut

$today = Get-Date -Format 'yyyy-MM-dd'
$total = $rows.Count
$byVerdict = $rows | Group-Object phase_a_verdict | Sort-Object Name
$byKind    = $rows | Group-Object proc_kind | Sort-Object Count -Descending

$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine("# Migration Blacklist - Phase A0 (OpsDB-only) - $today")
[void]$md.AppendLine("")
[void]$md.AppendLine("Source: ``dbo.ObjectsStatusHistory`` aggregated by ProcedureName.")
[void]$md.AppendLine("Universe: 1779 distinct procs in OpsDB. This file lists **$total** procs that fail at least one Phase-A0 deprecation rule.")
[void]$md.AppendLine("")
[void]$md.AppendLine("**Tick a checkbox = confirm DROP** (the migration runner will skip this proc).")
[void]$md.AppendLine("Leave unchecked = REPRIEVE (we'll migrate it; please add a one-line ``notes`` reason in the CSV).")
[void]$md.AppendLine("")
[void]$md.AppendLine("## Tally by verdict")
[void]$md.AppendLine("")
[void]$md.AppendLine("| Verdict | Procs |")
[void]$md.AppendLine("|---|---|")
foreach ($g in $byVerdict) { [void]$md.AppendLine("| $($g.Name) | $($g.Count) |") }
[void]$md.AppendLine("")
[void]$md.AppendLine("## Tally by proc kind")
[void]$md.AppendLine("")
[void]$md.AppendLine("| Kind | Procs | Notes |")
[void]$md.AppendLine("|---|---|---|")
$kindNotes = @{
    'synapse_sp'      = 'real Synapse stored procedure - primary blacklist target'
    'synapse_sp_lp'   = 'Synapse Loader Procedure (LP_*) - primary blacklist target'
    'copy_from_lake'  = 'DE_dbo.SP_CopyLakeToSynapse* - deprecated by generic pipeline'
    'databricks_job'  = 'BI_DataBricks-* - already-on-DBX job, no Synapse migration needed'
    'lake_path'       = 'Bronze/Silver/Gold/LP/etc lake-path identifier - generic-pipeline asset'
    'multi_ref'       = 'comma-separated multi-proc identifier - manual review'
    'dwh_meta'        = 'DWH-* metadata identifier - manual review'
    'other'           = 'unclassified - manual review'
}
foreach ($g in $byKind) {
    $note = if ($kindNotes.ContainsKey($g.Name)) { $kindNotes[$g.Name] } else { '' }
    [void]$md.AppendLine("| $($g.Name) | $($g.Count) | $note |")
}
[void]$md.AppendLine("")

foreach ($g in $byVerdict) {
    $verdict = $g.Name
    [void]$md.AppendLine("---")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("## $verdict ($($g.Count) procs)")
    [void]$md.AppendLine("")
    $verdictNotes = @{
        'A0_DISABLED'         = 'Already marked ``IsActive=False`` in OpsDB. Auto-confirm-drop unless someone reactivates.'
        'A0_GENERIC_PIPELINE' = 'ProcessType=5 (lake-side generic-pipeline asset). Already migrated; not a Synapse SP.'
        'A4_NEVER_SUCCEEDED'  = 'No successful run on record. Either always-failing or stub. Drop unless flagged for active dev.'
        'A4_DAILY_30D'        = 'Daily SP, last successful run 30-90 days ago. Likely silently failing.'
        'A4_DAILY_90D'        = 'Daily SP, last successful run 90-365 days ago. Strong drop candidate.'
        'A4_DAILY_365D'       = 'Daily SP, last successful run > 365 days ago. Strongest drop candidate.'
        'A4_HOURLY'           = 'Hourly SP, last successful run > 2 days ago.'
        'A4_MONTHLY'          = 'Monthly SP, last successful run > 45 days ago.'
        'A4_WEEKLY'           = 'Weekly SP, last successful run > 14 days ago.'
        'A4_QUARTERLY'        = 'Quarterly SP, last successful run > 100 days ago.'
    }
    if ($verdictNotes.ContainsKey($verdict)) { [void]$md.AppendLine($verdictNotes[$verdict]); [void]$md.AppendLine("") }

    $sub = $rows | Where-Object { $_.phase_a_verdict -eq $verdict } | Sort-Object @{e='proc_kind'},@{e='ProcedureName'}
    $byKindInVerdict = $sub | Group-Object proc_kind
    foreach ($kg in $byKindInVerdict) {
        [void]$md.AppendLine("### kind: $($kg.Name) ($($kg.Count))")
        [void]$md.AppendLine("")
        foreach ($r in $kg.Group) {
            $line = "- [ ] ``$($r.ProcedureName)``  | freq=$($r.FrequencySP) | last_success=$($r.last_success) | last_failure=$($r.last_failure) | succ_90d=$($r.successes_90d) | fail_90d=$($r.failures_90d)"
            [void]$md.AppendLine($line)
        }
        [void]$md.AppendLine("")
    }
}

[System.IO.File]::WriteAllText($MdOut, $md.ToString(), [System.Text.UTF8Encoding]::new($false))

"Wrote: $CsvOut"
"Wrote: $MdOut"
"Rows : $total"
