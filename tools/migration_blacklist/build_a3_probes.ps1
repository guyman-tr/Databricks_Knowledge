param(
    [Parameter(Mandatory=$true)] [string] $KeepCsv,
    [Parameter(Mandatory=$true)] [string] $OutDir,
    [int] $BatchSize = 30,
    [int] $InListMaxPerQuery = 400
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$keep = Import-Csv $KeepCsv

$colsDir = Join-Path $OutDir 'cols'
if (-not (Test-Path $colsDir)) { New-Item -ItemType Directory -Path $colsDir -Force | Out-Null }

$bySchema = $keep | Group-Object TableSchema
$colManifest = @()
foreach ($sg in $bySchema) {
    $schema = $sg.Name
    $names = $sg.Group | Select-Object -ExpandProperty BareTable -Unique
    $chunkIdx = 0
    for ($i=0; $i -lt $names.Count; $i += $InListMaxPerQuery) {
        $end = [Math]::Min($i + $InListMaxPerQuery, $names.Count) - 1
        $chunk = $names[$i..$end]
        $inList = ($chunk | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ','
        $sql = @"
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = '$schema'
  AND TABLE_NAME IN ($inList)
  AND COLUMN_NAME IN ('UpdateDate','LastUpdateDate','ModificationDate','ReportDateID','DateID','EOD_Date','EODDate','SnapshotDate','LoadDate','InsertDate','CreateDate','Date')
ORDER BY TABLE_NAME, COLUMN_NAME
"@
        $fn = "cols_${schema}_$('{0:D2}' -f $chunkIdx).sql"
        $path = Join-Path $colsDir $fn
        Set-Content -LiteralPath $path -Value $sql -Encoding UTF8
        $colManifest += [pscustomobject]@{
            file        = $path
            schema      = $schema
            table_count = $chunk.Count
        }
        $chunkIdx++
    }
}
$colManifest | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $OutDir '_cols_manifest.csv')

"Wrote $($colManifest.Count) column-resolution SQL files to $colsDir"
$colManifest | Format-Table -Auto | Out-String
