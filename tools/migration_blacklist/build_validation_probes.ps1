# Build INFORMATION_SCHEMA validation queries to confirm which keep-universe
# tables actually have an UpdateDate column. Each query is filtered by IN
# clause to the keep universe, so the result is bounded to ~one row per table.

[CmdletBinding()]
param(
    [string]$KeepCsv = '',
    [string]$OutDir  = '',
    [int]$BatchSize  = 200
)

$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($KeepCsv)) {
    $KeepCsv = Join-Path $ScriptRoot '..\..\audits\blacklist\_keep_universe_2026-05-31.csv'
}
if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $ScriptRoot '..\..\audits\blacklist\_a3_work\validate'
}
$KeepCsv = [IO.Path]::GetFullPath($KeepCsv)
$OutDir  = [IO.Path]::GetFullPath($OutDir)
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$rows = Import-Csv $KeepCsv

$tables = $rows |
    Where-Object { $_.TableSchema -in @('BI_DB_dbo','Dealing_dbo') } |
    Where-Object { $_.BareTable } |
    Sort-Object -Unique TableSchema, BareTable |
    ForEach-Object {
        [pscustomobject]@{
            Schema = $_.TableSchema.Trim()
            Table  = $_.BareTable.Trim()
        }
    }

$manifest = New-Object System.Collections.Generic.List[object]

foreach ($schemaGroup in ($tables | Group-Object Schema)) {
    $schema  = $schemaGroup.Name
    $entries = @($schemaGroup.Group)
    $i = 0
    $chunkIdx = 0
    while ($i -lt $entries.Count) {
        $end   = [Math]::Min($i + $BatchSize - 1, $entries.Count - 1)
        $chunk = $entries[$i..$end]
        $names = ($chunk | ForEach-Object { "'" + ($_.Table -replace "'", "''") + "'" }) -join ','

        $sql = @"
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = '$schema'
  AND TABLE_NAME IN ($names)
  AND COLUMN_NAME IN ('UpdateDate','LastUpdateDate','ModificationDate')
ORDER BY TABLE_NAME, COLUMN_NAME
"@

        $fname = ("validate_{0}_{1:00}.sql" -f $schema, $chunkIdx)
        $fpath = Join-Path $OutDir $fname
        Set-Content -Path $fpath -Value $sql -Encoding UTF8

        $manifest.Add([pscustomobject]@{
            file        = $fpath
            schema      = $schema
            chunk_index = $chunkIdx
            row_count   = $chunk.Count
        })

        $chunkIdx++
        $i = $end + 1
    }
}

$manifestPath = Join-Path $OutDir '_manifest.csv'
$manifest | Export-Csv -NoTypeInformation -Path $manifestPath
Write-Host "[validate] wrote $($manifest.Count) chunks; manifest: $manifestPath"
foreach ($m in $manifest) {
    Write-Host ("  - {0}  rows={1}" -f $m.file, $m.row_count)
}
