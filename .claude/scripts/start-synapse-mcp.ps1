<#
.SYNOPSIS
    Starts the Synapse MCP server in persistent SSE mode.
    Run this ONCE before launching the batch loop.
    One WAM auth popup, then the server stays alive for all iterations.

.DESCRIPTION
    The server listens on http://127.0.0.1:8766/sse.
    Claude Code connects to it via HTTP — no subprocess spawning,
    no re-authentication between iterations.

    Press Ctrl+C to stop the server when done.
#>

$serverScript = "C:\Users\guyman\.cursor\synapse-mcp-server.py"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Synapse MCP Server (SSE mode)" -ForegroundColor Cyan
Write-Host "  Port: 8766" -ForegroundColor Cyan
Write-Host "  URL:  http://127.0.0.1:8766/sse" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting server... a browser auth popup will appear ONCE." -ForegroundColor Yellow
Write-Host "After authenticating, leave this window open and" -ForegroundColor Yellow
Write-Host "run the batch loop in a SECOND PowerShell window." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop the server." -ForegroundColor Yellow
Write-Host ""

$env:MCP_SSE_MODE = "1"
$env:MCP_SSE_PORT = "8766"

python $serverScript
