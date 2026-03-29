$root = "C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki"
$files = Get-ChildItem $root -Recurse -Filter "*.alter.sql"
foreach ($f in $files) {
    $lines = Get-Content $f.FullName
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        if ($line -match 'ALTER COLUMN\s+(\S+)') {
            $col = $Matches[1]
            if ($col -match '^[^A-Za-z_]' -or $col -match '[^A-Za-z0-9_]') {
                Write-Output ("{0}:{1}  col=[{2}]" -f $f.Name, $lineNum, $col)
            }
        }
    }
}
