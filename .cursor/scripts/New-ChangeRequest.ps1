<#
.SYNOPSIS
    Creates a JSM Change Request (OC ticket) via the Service Desk API.
.PARAMETER TicketKey
    The source Jira ticket key (e.g., DSM-2790).
.PARAMETER ChangeType
    Default: "New Feature". Options: "New Feature", "Bug Fix", "Hotfix", "Configuration Change"
.PARAMETER DbaInvolved
    Flag if a DBA is involved. Default: not set (No).
.PARAMETER RollbackMinutes
    Rollback duration in minutes. Default: 10.
.PARAMETER DryRun
    Preview the payload without submitting.
.EXAMPLE
    .\New-ChangeRequest.ps1 -TicketKey "DSM-2790"
.EXAMPLE
    .\New-ChangeRequest.ps1 -TicketKey "DSM-2790" -ChangeType "Bug Fix" -DbaInvolved -DryRun
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$TicketKey,

    [string]$Summary,
    [string]$Description,

    [ValidateSet("New Feature", "Bug Fix", "Hotfix", "Configuration Change")]
    [string]$ChangeType = "New Feature",

    [string]$PlannedStart,
    [string]$PlannedEnd,

    [switch]$DbaInvolved,
    [int]$RollbackMinutes = 10,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# ── Configuration ────────────────────────────────────────────────
$JiraBaseUrl   = "https://etoro-jira.atlassian.net"
$ServiceDeskId = "1073"
$RequestTypeId = "1133"

$ChangeTypeMap = @{
    "New Feature"          = "18888"
    "Bug Fix"              = "18889"
    "Hotfix"               = "18890"
    "Configuration Change" = "18891"
}

# ── Credentials ──────────────────────────────────────────────────
$credFile = Join-Path $PSScriptRoot "jira-creds.json"
$headers = $null

$needsCreds = (-not $DryRun) -or (-not $Summary)

if ($needsCreds) {
    if (-not (Test-Path $credFile)) {
        Write-Host ""
        Write-Host "First-time setup: Atlassian API token required" -ForegroundColor Yellow
        Write-Host "1. Go to: https://id.atlassian.com/manage-profile/security/api-tokens" -ForegroundColor Yellow
        Write-Host "2. Create a token labeled: deploy-approval-automation" -ForegroundColor Yellow
        Write-Host ""

        $email = Read-Host "Atlassian email"
        $tokenSecure = Read-Host "API token" -AsSecureString
        $tokenPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($tokenSecure)
        )

        $credObj = @{ email = $email; token = $tokenPlain }
        $credObj | ConvertTo-Json | Set-Content $credFile -Encoding UTF8
        Write-Host "Credentials saved to $credFile (gitignored)" -ForegroundColor Green
    }

    $creds = Get-Content $credFile -Raw | ConvertFrom-Json
    $pair = "$($creds.email):$($creds.token)"
    $authBytes = [Text.Encoding]::ASCII.GetBytes($pair)
    $authHeader = [Convert]::ToBase64String($authBytes)

    $headers = @{
        "Authorization" = "Basic $authHeader"
        "Content-Type"  = "application/json"
        "Accept"        = "application/json"
    }
}

# ── Read source ticket ──────────────────────────────────────────
$ticketSummary = $Summary
$ticketDesc = $Description

if (-not $ticketSummary -and $null -ne $headers) {
    Write-Host "Reading $TicketKey ..." -ForegroundColor Cyan
    $issueUrl = "$JiraBaseUrl/rest/api/3/issue/$TicketKey"
    try {
        $issue = Invoke-RestMethod -Uri $issueUrl -Headers $headers -Method Get
    }
    catch {
        Write-Error "Failed to read $TicketKey - check ticket key and credentials"
        exit 1
    }

    $ticketSummary = $issue.fields.summary

    if ($null -ne $issue.fields.description) {
        if ($issue.fields.description -is [string]) {
            $ticketDesc = $issue.fields.description
        }
        else {
            $parts = @()
            foreach ($block in $issue.fields.description.content) {
                if ($null -ne $block.content) {
                    foreach ($inline in $block.content) {
                        if ($null -ne $inline.text) { $parts += $inline.text }
                    }
                }
            }
            if ($parts.Count -gt 0) { $ticketDesc = $parts -join " " }
        }
    }
}

if (-not $ticketSummary) { $ticketSummary = $TicketKey }
if (-not $ticketDesc) { $ticketDesc = $ticketSummary }

# ── Deployment window ───────────────────────────────────────────
if (-not $PlannedStart -or -not $PlannedEnd) {
    $candidate = (Get-Date).AddDays(1)
    while ($candidate.DayOfWeek -eq [DayOfWeek]::Friday -or $candidate.DayOfWeek -eq [DayOfWeek]::Saturday) {
        $candidate = $candidate.AddDays(1)
    }
    if (-not $PlannedStart) {
        $PlannedStart = $candidate.Date.AddHours(8).ToString("yyyy-MM-ddTHH:mm:ss.000+0200")
    }
    if (-not $PlannedEnd) {
        $PlannedEnd = $candidate.Date.AddHours(14).ToString("yyyy-MM-ddTHH:mm:ss.000+0200")
    }
}

# ── Build payload ───────────────────────────────────────────────
$dbaOptId = "18906"
if ($DbaInvolved) { $dbaOptId = "18907" }

$dbaLabel = "No"
if ($DbaInvolved) { $dbaLabel = "Yes" }

$fieldValues = [ordered]@{
    summary           = $ticketSummary
    description       = $ticketDesc
    customfield_10369 = $TicketKey
    customfield_14177 = @{ id = $ChangeTypeMap[$ChangeType] }
    customfield_14180 = @{ id = "18899" }
    customfield_14181 = @{ id = "18904" }
    customfield_14184 = @{ id = $dbaOptId }
    customfield_14185 = @{ id = "18908" }
    customfield_14186 = $RollbackMinutes
    customfield_14188 = "none"
    customfield_10602 = @{ id = "12043" }
    customfield_14194 = @{ id = "20126" }
    customfield_10494 = @{ id = "11270" }
    customfield_15381 = $PlannedStart
    customfield_15382 = $PlannedEnd
}

$body = @{
    serviceDeskId      = $ServiceDeskId
    requestTypeId      = $RequestTypeId
    requestFieldValues = $fieldValues
}

$payload = $body | ConvertTo-Json -Depth 5

# ── Display summary ─────────────────────────────────────────────
Write-Host ""
Write-Host "=== DEPLOY APPROVAL : $TicketKey ===" -ForegroundColor Green
Write-Host "  Summary:           $ticketSummary"
$descPreview = $ticketDesc
if ($descPreview.Length -gt 80) { $descPreview = $descPreview.Substring(0, 80) + "..." }
Write-Host "  Description:       $descPreview"
Write-Host ""
Write-Host "  Change Type:       $ChangeType"
Write-Host "  Downtime:          No"
Write-Host "  Business Impact:   No"
Write-Host "  DBA Involved:      $dbaLabel"
Write-Host "  Multiple Domains:  No"
Write-Host "  Rollback Duration: $RollbackMinutes minutes"
Write-Host "  Rollback Tested:   Yes"
Write-Host "  Validation:        Tested in alternative lower environment"
Write-Host ""
Write-Host "  Planned Start:     $PlannedStart"
Write-Host "  Planned End:       $PlannedEnd"
Write-Host "===================================" -ForegroundColor Green
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN - payload:" -ForegroundColor Yellow
    Write-Host $payload
    exit 0
}

# ── Submit ───────────────────────────────────────────────────────
Write-Host "Submitting Change Request ..." -ForegroundColor Cyan

$sdUrl = "$JiraBaseUrl/rest/servicedeskapi/request"
try {
    $response = Invoke-RestMethod -Uri $sdUrl -Headers $headers -Method Post -Body $payload
}
catch {
    $errMsg = $_.Exception.Message
    $errBody = ""
    if ($_.ErrorDetails) { $errBody = $_.ErrorDetails.Message }
    Write-Host "API Error: $errMsg" -ForegroundColor Red
    if ($errBody) { Write-Host "Details: $errBody" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Falling back to portal URL ..." -ForegroundColor Yellow

    Add-Type -AssemblyName System.Web
    $encSummary = [System.Web.HttpUtility]::UrlEncode($ticketSummary)
    $encDesc    = [System.Web.HttpUtility]::UrlEncode($ticketDesc)
    $portalUrl  = "$JiraBaseUrl/servicedesk/customer/portal/$ServiceDeskId/group/1090/create/$RequestTypeId"
    $portalUrl += "?customfield_10369=$TicketKey&summary=$encSummary&description=$encDesc"

    Write-Host "Portal URL:" -ForegroundColor Green
    Write-Host $portalUrl
    Start-Process $portalUrl
    exit 1
}

$ocKey = $response.issueKey
$ocUrl = "$JiraBaseUrl/browse/$ocKey"

Write-Host ""
Write-Host "  Created: $ocKey" -ForegroundColor Green
Write-Host "  URL:     $ocUrl" -ForegroundColor Green
Write-Host ""

# ── Link tickets ────────────────────────────────────────────────
Write-Host "Linking $ocKey to $TicketKey ..." -ForegroundColor Cyan

$linkBody = @{
    type = @{ name = "Defect" }
    inwardIssue  = @{ key = $TicketKey }
    outwardIssue = @{ key = $ocKey }
} | ConvertTo-Json -Depth 3

$linkUrl = "$JiraBaseUrl/rest/api/3/issueLink"
try {
    Invoke-RestMethod -Uri $linkUrl -Headers $headers -Method Post -Body $linkBody | Out-Null
    Write-Host "  Linked: $TicketKey <-> $ocKey" -ForegroundColor Green
}
catch {
    Write-Host "  Could not auto-link. Link manually in Jira." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Done. Approval workflow started." -ForegroundColor Green
Write-Host "  Track at: $ocUrl" -ForegroundColor DarkGray
