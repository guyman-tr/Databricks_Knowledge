param([string]$Dir)
Get-ChildItem "$Dir\*.alter.sql" | ForEach-Object {
    $name = $_.BaseName -replace '\.alter$',''
    $alterCount = (Select-String 'ALTER COLUMN' $_.FullName).Count
    $mdPath = Join-Path $_.DirectoryName "$name.md"
    if (Test-Path $mdPath) {
        $wikiCount = (Select-String '^\| \d+' $mdPath).Count
        $diff = $wikiCount - $alterCount
        if ($diff -ne 0) {
            Write-Output "$name : wiki=$wikiCount alter=$alterCount diff=$diff"
        }
    }
}
