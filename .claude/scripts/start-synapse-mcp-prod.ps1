<#
.SYNOPSIS
    Starts a SECOND Synapse MCP server (PROD pool) in SSE mode.
    Does not change the default STG server (port 8766).

.DESCRIPTION
    Listens on http://127.0.0.1:8767/sse with sql_dp_prod_we.
    Run alongside start-synapse-mcp.ps1 if you need both STG and PROD in Cursor.

    Add to .mcp.json (see repo): "synapse_prod_sql" -> http://127.0.0.1:8767/sse

    One WAM/MFA popup may appear on first connect (or reuses cache from STG).
#>

$serverScript = "C:\Users\guyman\.cursor\synapse-mcp-server.py"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host '  Synapse MCP Server — PROD (SSE)' -ForegroundColor Magenta
Write-Host "  Pool: sql_dp_prod_we" -ForegroundColor Magenta
Write-Host "  Port: 8767" -ForegroundColor Magenta
Write-Host "  URL:  http://127.0.0.1:8767/sse" -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "STG remains on 8766 — this is a separate process for PROD only." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

$env:MCP_SSE_MODE = "1"
$env:MCP_SSE_PORT = "8767"
$env:SYNAPSE_SERVER = "prod-synapse-dataplatform-we.sql.azuresynapse.net"
$env:SYNAPSE_DATABASE = "sql_dp_prod_we"

python $serverScript
