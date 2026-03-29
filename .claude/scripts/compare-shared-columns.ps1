param(
    [string]$File1,
    [string]$File2
)

function Get-Elements($path) {
    $lines = Get-Content $path
    $elements = @{}
    $inElements = $false
    foreach ($line in $lines) {
        if ($line -match '^## 4\. Elements') { $inElements = $true; continue }
        if ($inElements -and $line -match '^## \d+\.') { break }
        if ($inElements -and $line -match '^\|\s*\d+\s*\|\s*(\S+)\s*\|.*\|.*\|\s*(.+?)\s*\|$') {
            $colName = $Matches[1].Trim()
            $desc = $Matches[2].Trim()
            $elements[$colName] = $desc
        }
    }
    return $elements
}

$name1 = [System.IO.Path]::GetFileNameWithoutExtension($File1)
$name2 = [System.IO.Path]::GetFileNameWithoutExtension($File2)

$e1 = Get-Elements $File1
$e2 = Get-Elements $File2

Write-Host "=== Shared columns between $name1 ($($e1.Count) cols) and $name2 ($($e2.Count) cols) ===" -ForegroundColor Cyan
Write-Host ""

$shared = 0
$different = 0
$same = 0

foreach ($col in $e1.Keys) {
    if ($e2.ContainsKey($col)) {
        $shared++
        $d1 = $e1[$col]
        $d2 = $e2[$col]
        if ($d1 -ne $d2) {
            $different++
            Write-Host "DIFF: $col" -ForegroundColor Yellow
            Write-Host "  $name1 : $d1" -ForegroundColor Red
            Write-Host "  $name2 : $d2" -ForegroundColor Green
            Write-Host ""
        } else {
            $same++
        }
    }
}

Write-Host "--- Summary ---" -ForegroundColor Cyan
Write-Host "Shared columns: $shared"
Write-Host "Identical descriptions: $same"
Write-Host "Different descriptions: $different"
