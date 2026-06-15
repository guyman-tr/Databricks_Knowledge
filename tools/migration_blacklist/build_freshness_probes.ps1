# Build Synapse MAX(UpdateDate) freshness probes for the keep universe.
# Output: chunked SQL files (UNION ALL) ready to fire via MCP.
#
# Strategy: virtually every BI_DB_dbo + Dealing_dbo table has an UpdateDate
# column. Dealing_staging is dominated by External_* tables which proxy other
# databases and rarely carry an UpdateDate, so we exclude that schema from the
# first pass.
#
# Each probe row:
#   SELECT '<schema>' AS schema_name, '<table>' AS table_name,
#          CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update
#   FROM   [<schema>].[<table>]
#
# Failures (missing column / missing table) will be retried with fallback
# columns in a follow-up pass.

[CmdletBinding()]
param(
    [string]$KeepCsv = '',
    [string]$OutDir  = '',
    [int]$ChunkSize  = 25
)

$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($KeepCsv)) {
    $KeepCsv = Join-Path $ScriptRoot '..\..\audits\blacklist\_keep_universe_2026-05-31.csv'
}
if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $ScriptRoot '..\..\audits\blacklist\_a3_work\probes'
}
$KeepCsv = [IO.Path]::GetFullPath($KeepCsv)
$OutDir  = [IO.Path]::GetFullPath($OutDir)
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

Write-Host "[freshness] reading keep universe: $KeepCsv"
$rows = Import-Csv $KeepCsv

# Drop dups (same TableName feeding multiple SPs we only need one probe row).
$tables = $rows |
    Where-Object { $_.TableSchema -in @('BI_DB_dbo','Dealing_dbo') } |
    Where-Object { $_.BareTable -and $_.BareTable -notmatch '^\s*$' } |
    Sort-Object -Unique TableSchema, BareTable |
    ForEach-Object {
        [pscustomobject]@{
            Schema = $_.TableSchema.Trim()
            Table  = $_.BareTable.Trim()
        }
    }

Write-Host ("[freshness] {0} unique probe targets" -f $tables.Count)

$manifest = New-Object System.Collections.Generic.List[object]

foreach ($schemaGroup in ($tables | Group-Object Schema)) {
    $schema  = $schemaGroup.Name
    $entries = @($schemaGroup.Group)
    $i = 0
    $chunkIdx = 0
    while ($i -lt $entries.Count) {
        $end   = [Math]::Min($i + $ChunkSize - 1, $entries.Count - 1)
        $chunk = $entries[$i..$end]

        $sb = New-Object System.Text.StringBuilder
        for ($j = 0; $j -lt $chunk.Count; $j++) {
            $t = $chunk[$j]
            $line = "SELECT '{0}' AS schema_name, '{1}' AS table_name, CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update FROM [{0}].[{1}]" -f $t.Schema, ($t.Table -replace "'", "''")
            if ($j -lt $chunk.Count - 1) { $line += ' UNION ALL' }
            [void]$sb.AppendLine($line)
        }

        $fname  = ("probe_{0}_{1:00}.sql" -f $schema, $chunkIdx)
        $fpath  = Join-Path $OutDir $fname
        # Use System.IO.File to write without BOM (Synapse parser dislikes BOM).
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($fpath, $sb.ToString(), $utf8NoBom)

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
Write-Host "[freshness] wrote $($manifest.Count) chunks; manifest: $manifestPath"
