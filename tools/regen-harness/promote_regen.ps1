<#
.SYNOPSIS
  Promote a regenerated wiki from audits/regen-sample/ over the live wiki tree.

.DESCRIPTION
  For one or more objects, this script:
    1. Reads audits/regen-sample/{Schema}/{Object}/compare.md to verify the
       judge verdict is BETTER or EQUIVALENT.
    2. Locates the live wiki at knowledge/synapse/Wiki/{Schema}/{Tables|Views|Functions}/{Object}.md.
    3. Shows the file-by-file diff and a 1-line summary.
    4. If -Apply is set: copies regen/final/{Object}.md (+ .lineage.md, +
       .review-needed.md if present) over the live files. Original files are
       backed up to a .bak suffix in the same dir before overwrite (single
       generation kept).

  DRY-RUN BY DEFAULT. No -Apply means no writes.

.PARAMETER Object
  Single object name (without schema prefix). Use with -Schema.

.PARAMETER Schema
  Schema name. Required when -Object is used.

.PARAMETER FromList
  Path to a text file with one "Schema.Object" per line. Lines starting with #
  are ignored. Use INSTEAD of -Schema/-Object.

.PARAMETER Apply
  Actually write changes. Without this flag, only diffs are shown.

.PARAMETER AcceptVerdicts
  Comma-separated verdicts to accept. Default: BETTER,EQUIVALENT.
  Pass "BETTER,EQUIVALENT,WORSE" only if you have manually validated the WORSE ones.

.PARAMETER NoBackup
  Skip writing the .bak files when -Apply is set. Default writes them.

.EXAMPLE
  # Dry-run a single object
  .\promote_regen.ps1 -Schema DWH_dbo -Object Dim_Channel

.EXAMPLE
  # Apply for a single object (after reviewing the dry-run output)
  .\promote_regen.ps1 -Schema DWH_dbo -Object Dim_Channel -Apply

.EXAMPLE
  # Dry-run a list of objects
  .\promote_regen.ps1 -FromList .\audits\regen-sample\_phase2_approved.txt

.EXAMPLE
  # Apply for the whole approved list
  .\promote_regen.ps1 -FromList .\audits\regen-sample\_phase2_approved.txt -Apply
#>
[CmdletBinding(DefaultParameterSetName='Single')]
param(
    [Parameter(Mandatory=$true,  ParameterSetName='Single')] [string] $Schema,
    [Parameter(Mandatory=$true,  ParameterSetName='Single')] [string] $Object,
    [Parameter(Mandatory=$true,  ParameterSetName='List')]   [string] $FromList,
    [Parameter(Mandatory=$false)]                             [switch] $Apply,
    [Parameter(Mandatory=$false)]                             [string] $AcceptVerdicts = "BETTER,EQUIVALENT",
    [Parameter(Mandatory=$false)]                             [switch] $NoBackup
)

$ErrorActionPreference = 'Stop'
$harnessRoot = Split-Path -Parent $PSCommandPath
$repoRoot = (Get-Item (Join-Path $harnessRoot "..\..\")).FullName
$wikiRoot  = Join-Path $repoRoot "knowledge\synapse\Wiki"
$auditRoot = Join-Path $repoRoot "audits\regen-sample"

$acceptedSet = @{}
foreach ($v in ($AcceptVerdicts -split ',')) { $acceptedSet[$v.Trim().ToUpper()] = $true }

function Get-ObjectList {
    if ($PSCmdlet.ParameterSetName -eq 'Single') {
        return ,([pscustomobject]@{ Schema = $Schema; Object = $Object })
    }
    $list = New-Object System.Collections.Generic.List[psobject]
    if (-not (Test-Path $FromList)) {
        throw "FromList not found: $FromList"
    }
    $lines = Get-Content -Path $FromList -Encoding UTF8
    foreach ($line in $lines) {
        $t = $line.Trim()
        if (-not $t) { continue }
        if ($t.StartsWith("#")) { continue }
        $parts = $t.Split(".", 2)
        if ($parts.Count -ne 2) {
            Write-Host ("  skip (cannot parse '{0}')" -f $t) -ForegroundColor Yellow
            continue
        }
        $list.Add([pscustomobject]@{ Schema = $parts[0]; Object = $parts[1] })
    }
    return $list
}

function Find-LiveWikiPath([string]$schema, [string]$obj) {
    foreach ($sub in @("Tables","Views","Functions")) {
        $cand = Join-Path $wikiRoot ("{0}\{1}\{2}.md" -f $schema, $sub, $obj)
        if (Test-Path $cand) { return @{ Wiki = $cand; Subdir = $sub } }
    }
    return $null
}

function Read-VerdictFromCompare([string]$comparePath) {
    if (-not (Test-Path $comparePath)) { return $null }
    $text = Get-Content -Path $comparePath -Encoding UTF8 -Raw
    $m = [regex]::Match($text, '\*\*Verdict\*\*:\s*\*\*(\w+)\*\*')
    if ($m.Success) { return $m.Groups[1].Value.ToUpper() }
    return $null
}

function Show-DiffSummary([string]$src, [string]$dst, [string]$label) {
    if (-not (Test-Path $dst)) {
        Write-Host ("    {0,-22} new file (no current)" -f $label) -ForegroundColor Yellow
        return
    }
    $srcLines = (Get-Content -Path $src -Encoding UTF8).Length
    $dstLines = (Get-Content -Path $dst -Encoding UTF8).Length
    $srcBytes = (Get-Item $src).Length
    $dstBytes = (Get-Item $dst).Length
    $deltaL = $srcLines - $dstLines
    $deltaB = $srcBytes - $dstBytes
    $sign1 = if ($deltaL -ge 0) { "+" } else { "" }
    $sign2 = if ($deltaB -ge 0) { "+" } else { "" }
    Write-Host ("    {0,-22} live={1,5} -> regen={2,5} ({3}{4} lines, {5}{6} bytes)" -f $label, $dstLines, $srcLines, $sign1, $deltaL, $sign2, $deltaB) -ForegroundColor Gray
}

function Promote-One([string]$schema, [string]$obj) {
    Write-Host ""
    Write-Host ("=== {0}.{1} ===" -f $schema, $obj) -ForegroundColor Cyan

    $objDir = Join-Path $auditRoot ("{0}\{1}" -f $schema, $obj)
    if (-not (Test-Path $objDir)) {
        Write-Host ("  SKIP: no audits/regen-sample folder for this object: {0}" -f $objDir) -ForegroundColor Yellow
        return [pscustomobject]@{ Schema=$schema; Object=$obj; Action="skip"; Reason="no_audit_dir" }
    }

    $comparePath = Join-Path $objDir "compare.md"
    $verdict = Read-VerdictFromCompare $comparePath
    if (-not $verdict) {
        Write-Host ("  SKIP: no readable compare.md verdict at {0}" -f $comparePath) -ForegroundColor Yellow
        return [pscustomobject]@{ Schema=$schema; Object=$obj; Action="skip"; Reason="no_verdict" }
    }
    if (-not $acceptedSet.ContainsKey($verdict)) {
        Write-Host ("  SKIP: verdict {0} not in accepted set ({1})" -f $verdict, $AcceptVerdicts) -ForegroundColor Yellow
        return [pscustomobject]@{ Schema=$schema; Object=$obj; Action="skip"; Reason="verdict_$verdict" }
    }
    Write-Host ("  Verdict: {0}" -f $verdict) -ForegroundColor Green

    $finalDir = Join-Path $objDir "regen\final"
    if (-not (Test-Path $finalDir)) {
        Write-Host ("  SKIP: no regen/final dir at {0}" -f $finalDir) -ForegroundColor Yellow
        return [pscustomobject]@{ Schema=$schema; Object=$obj; Action="skip"; Reason="no_final_dir" }
    }

    $live = Find-LiveWikiPath $schema $obj
    if (-not $live) {
        Write-Host ("  SKIP: live wiki not found in any of Tables/Views/Functions for {0}.{1}" -f $schema, $obj) -ForegroundColor Yellow
        return [pscustomobject]@{ Schema=$schema; Object=$obj; Action="skip"; Reason="live_wiki_missing" }
    }
    $liveDir = Split-Path -Parent $live.Wiki

    $toCopy = @()
    foreach ($suffix in @(".md", ".lineage.md", ".review-needed.md")) {
        $srcFile = Join-Path $finalDir ("{0}{1}" -f $obj, $suffix)
        $dstFile = Join-Path $liveDir ("{0}{1}" -f $obj, $suffix)
        if (Test-Path $srcFile) {
            $toCopy += [pscustomobject]@{ Src = $srcFile; Dst = $dstFile; Suffix = $suffix }
        }
    }
    if ($toCopy.Count -eq 0) {
        Write-Host ("  SKIP: regen/final has no {0}.md (or sidecars)" -f $obj) -ForegroundColor Yellow
        return [pscustomobject]@{ Schema=$schema; Object=$obj; Action="skip"; Reason="no_regen_files" }
    }

    Write-Host ("  Live dir: {0}" -f $liveDir) -ForegroundColor Gray
    foreach ($pair in $toCopy) {
        Show-DiffSummary -src $pair.Src -dst $pair.Dst -label $pair.Suffix
    }

    if (-not $Apply) {
        Write-Host "  (dry-run: no files written. Re-run with -Apply to promote.)" -ForegroundColor DarkGray
        return [pscustomobject]@{ Schema=$schema; Object=$obj; Action="dry_run"; Reason=$verdict; Files=$toCopy.Count }
    }

    foreach ($pair in $toCopy) {
        if ((Test-Path $pair.Dst) -and (-not $NoBackup)) {
            $bak = "$($pair.Dst).bak"
            Copy-Item -Path $pair.Dst -Destination $bak -Force
        }
        Copy-Item -Path $pair.Src -Destination $pair.Dst -Force
        Write-Host ("    wrote {0}" -f $pair.Dst) -ForegroundColor Green
    }
    return [pscustomobject]@{ Schema=$schema; Object=$obj; Action="applied"; Reason=$verdict; Files=$toCopy.Count }
}

$objects = Get-ObjectList
Write-Host ""
Write-Host ("Promote-Regen  ({0} objects, Apply={1}, AcceptVerdicts={2})" -f $objects.Count, $Apply.IsPresent, $AcceptVerdicts) -ForegroundColor Cyan

$results = @()
foreach ($pair in $objects) {
    try {
        $r = Promote-One -schema $pair.Schema -obj $pair.Object
        if ($r) { $results += $r }
    } catch {
        Write-Host ("  ERROR for {0}.{1}: {2}" -f $pair.Schema, $pair.Object, $_.Exception.Message) -ForegroundColor Red
        $results += [pscustomobject]@{ Schema=$pair.Schema; Object=$pair.Object; Action="error"; Reason=$_.Exception.Message }
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$grp = $results | Group-Object Action
foreach ($g in $grp) {
    Write-Host ("  {0,-10} {1}" -f $g.Name, $g.Count) -ForegroundColor White
}

# Write a side log of what happened
$logPath = Join-Path $auditRoot ("_promote_log_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$results | Export-Csv -Path $logPath -NoTypeInformation -Encoding UTF8
Write-Host ("  Log: {0}" -f $logPath) -ForegroundColor Gray

if (-not $Apply) {
    Write-Host ""
    Write-Host "DRY-RUN. No files were written. Re-run with -Apply to promote." -ForegroundColor Yellow
}

exit 0
