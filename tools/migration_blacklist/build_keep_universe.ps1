param(
    [Parameter(Mandatory=$true)] [string] $A0CsvPath,
    [Parameter(Mandatory=$true)] [string] $OutCsv
)

$ErrorActionPreference = 'Stop'

$configPath = '.specify\Configs\opsdb-objects-status.json'
$static = Get-Content $configPath -Raw | ConvertFrom-Json
$a0     = Import-Csv $A0CsvPath
$dropped = $a0 | Select-Object -ExpandProperty ProcedureName | Sort-Object -Unique
$droppedSet = @{}
foreach ($p in $dropped) { $droppedSet[$p] = $true }

$keep = @()
foreach ($r in $static) {
    if ($droppedSet.ContainsKey($r.ProcedureName)) { continue }
    if ($r.ProcessType -eq 5) { continue }
    if ($r.TableName -notmatch '\.') { continue }
    if ($r.TableName -match '/') { continue }
    $parts = $r.TableName -split '\.', 2
    if ($parts.Count -ne 2) { continue }
    $schema = $parts[0]
    $bare = $parts[1]
    if ($bare -match '/') { continue }
    if ($schema -notin @('BI_DB_dbo','Dealing_dbo','Dealing_staging','DWH_dbo','DWH_watchlists','DWH_pagetracking','eMoney_dbo','EXW_dbo','BI_DB_Migration','DE_dbo')) { continue }
    $keep += [pscustomobject]@{
        ProcedureName = $r.ProcedureName
        TableName     = $r.TableName
        TableSchema   = $schema
        BareTable     = $bare
        FrequencySP   = $r.FrequencySP
        Priority      = $r.Priority
        ProcessType   = $r.ProcessType
        ProcessName   = $r.ProcessName
    }
}

$keep | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath $OutCsv
"static_total: $($static.Count)"
"a0_dropped:   $($dropped.Count)"
"keep_total:   $($keep.Count)"
"by schema:"
$keep | Group-Object TableSchema | Sort-Object Count -Desc | ForEach-Object { "  $($_.Name): $($_.Count)" }
