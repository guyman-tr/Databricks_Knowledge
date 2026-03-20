Write-Host "=== Files with ZERO Tier 1 (candidates for upgrade) ==="
Write-Host ""
$zeroT1 = @()
$hasT1 = @()

Get-ChildItem 'knowledge\synapse\Wiki\DWH_dbo\Tables\*.md' -Exclude '*.lineage.md','*.review-needed.md','_*' | ForEach-Object {
    $name = $_.BaseName
    $lines = Get-Content $_.FullName -Encoding UTF8
    $t1 = 0
    $t2 = 0
    foreach ($line in $lines) {
        if ($line -match '\(Tier 1') { $t1++ }
        if ($line -match '\(Tier 2') { $t2++ }
    }
    $total = $t1 + $t2
    if ($t1 -eq 0 -and $t2 -gt 0) {
        $zeroT1 += [PSCustomObject]@{Name=$name; T2=$t2}
    } elseif ($t1 -gt 0) {
        $hasT1 += [PSCustomObject]@{Name=$name; T1=$t1; T2=$t2; Total=$total}
    }
}

foreach ($f in $zeroT1 | Sort-Object Name) {
    Write-Host ("{0,-55} T2={1}" -f $f.Name, $f.T2)
}

Write-Host ""
Write-Host "=== Files WITH Tier 1 (already done or partially done) ==="
Write-Host ""
foreach ($f in $hasT1 | Sort-Object Name) {
    Write-Host ("{0,-55} T1={1,-4} T2={2,-4} Total={3}" -f $f.Name, $f.T1, $f.T2, $f.Total)
}

Write-Host ""
Write-Host "Summary: $($zeroT1.Count) files with 0 T1, $($hasT1.Count) files with T1"
