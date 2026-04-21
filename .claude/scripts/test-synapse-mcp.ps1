$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$claudePath = "$env:APPDATA\npm\claude.cmd"

$prompt = "Use the synapse_sql MCP tool to run this query: SELECT TOP 5 CountryID, Country FROM DWH_dbo.Dim_Country ORDER BY CountryID. Print the results as a table."

$proc = Start-Process -FilePath $claudePath `
    -ArgumentList "--dangerously-skip-permissions --print `"$prompt`"" `
    -WorkingDirectory $repoRoot `
    -PassThru -NoNewWindow -Wait

Write-Host ""
Write-Host "Exit code: $($proc.ExitCode)"
