# Test-QualityDrift.ps1 -- detect quality drift in the wiki documentation loop.
#
# Why this exists:
#   With BI_DB_dbo batch size bumped from 4 to 8 (Workstream 1b), there is a
#   real risk that Phase 16 quality scores drift downward as the agent's
#   per-object attention thins out. We need a cheap, deterministic guard that:
#     1. Detects drift early (after each batch, not days later).
#     2. Throttles the next batch back to 4 if drift is mild.
#     3. Kills the loop if drift is severe (so we don't burn tokens on garbage).
#
# Design:
#   The canonical record of per-object quality is `_index.md`. Every completed
#   batch has a markdown table with a Quality column (e.g. `8.93`) for each
#   object. We parse the last N batches, compute medians, and apply thresholds.
#
#   We use MEDIAN (not mean) for the baseline because individual batches
#   sometimes contain intrinsically low-scoring objects (decommissioned/empty
#   tables that score 5.0-6.5 regardless of agent quality). Median is robust
#   to those outliers.
#
# Inputs:
#   -SchemaName              Schema to check (e.g. "BI_DB_dbo")
#   -RepoRoot                Databricks_Knowledge repo root
#   -DefaultBatchSize        The schema's normal batch size (e.g. 8 for BI_DB)
#   -ThrottledBatchSize      Reduced batch size when drift detected (default 4)
#   -RecentBatches           How many recent batches count as "recent" (default 1)
#   -BaselineBatches         How many batches before recent count as baseline (default 6)
#   -ThrottleAbsThreshold    Recent_avg below baseline_median - this -> throttle (default 0.5)
#   -ThrottleFailFraction    Fraction of last batch < 7.5 that triggers throttle (default 0.5)
#   -KillAvgThreshold        Recent batch avg below this -> kill (default 6.5)
#   -KillConsecutiveDrifts   N consecutive drifts -> kill (default 3)
#
# Output:
#   Hashtable: @{
#       NextBatchSize    = int       # Recommended size for next iteration
#       ShouldKill       = bool      # If true, caller should exit the loop
#       Reason           = string    # Human-readable explanation
#       DriftLevel       = string    # 'none' | 'mild' | 'severe'
#       LastBatchAvg     = double    # Average score of last batch (-1 if no data)
#       LastBatchMin     = double    # Lowest score in last batch (-1 if no data)
#       LastBatchScores  = double[]  # All scores in last batch
#       BaselineMedian   = double    # Median across baseline batches
#       BaselineSampleN  = int       # Number of objects in baseline
#       LastBatchNumber  = int       # The batch number we evaluated as "last"
#   }
#
# State file:
#   $RepoRoot\.claude\state\quality_drift_history.jsonl -- one line per drift
#   evaluation, persists across runs so we can detect "consecutive drifts"
#   even if the loop is restarted between iterations.

function Test-QualityDrift {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string] $SchemaName,
        [string] $RepoRoot              = "C:\Users\guyman\Documents\github\Databricks_Knowledge",
        [int]    $DefaultBatchSize      = 8,
        [int]    $ThrottledBatchSize    = 4,
        [int]    $RecentBatches         = 1,
        [int]    $BaselineBatches       = 6,
        [double] $ThrottleAbsThreshold  = 0.5,
        [double] $ThrottleFailFraction  = 0.5,
        [double] $KillAvgThreshold      = 6.5,
        [int]    $KillConsecutiveDrifts = 3
    )

    $indexPath = Join-Path $RepoRoot "knowledge\synapse\Wiki\$SchemaName\_index.md"
    $stateDir  = Join-Path $RepoRoot ".claude\state"
    $statePath = Join-Path $stateDir "quality_drift_history_$SchemaName.jsonl"

    $result = @{
        NextBatchSize    = $DefaultBatchSize
        ShouldKill       = $false
        Reason           = ""
        DriftLevel       = "none"
        LastBatchAvg     = -1.0
        LastBatchMin     = -1.0
        LastBatchScores  = @()
        BaselineMedian   = -1.0
        BaselineSampleN  = 0
        LastBatchNumber  = -1
    }

    if (-not (Test-Path $indexPath)) {
        $result.Reason = "Index not found: $indexPath -- skipping drift check (first batch?)"
        return $result
    }

    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }

    # ---- Parse _index.md into per-batch score lists ------------------------
    # Each batch section starts with "## Batch N (...)" and contains a markdown
    # table with the columns: # | Object | Type | Priority | Quality | Status.
    # We just need batch number + score from "Done (Batch N)" rows.
    $lines = Get-Content $indexPath -ErrorAction SilentlyContinue
    if (-not $lines) {
        $result.Reason = "Index empty -- skipping drift check"
        return $result
    }

    $batchScores  = @{}     # batchNum -> list of [double] scores
    $currentBatch = $null

    foreach ($ln in $lines) {
        if ($ln -match '^##\s+Batch\s+(\d+)\s+') {
            $currentBatch = [int]$Matches[1]
            if (-not $batchScores.ContainsKey($currentBatch)) {
                $batchScores[$currentBatch] = New-Object System.Collections.Generic.List[double]
            }
            continue
        }
        if ($null -eq $currentBatch) { continue }
        # Match table rows that end with "Done (Batch N)" and have a numeric Quality column.
        # Format: | NN | [link] | Type | Priority | Quality | Done (Batch N) |
        # Quality is the 5th cell (index 4) — but priority can be empty / "-" so use
        # a more permissive pattern: pull last numeric cell before "Done".
        if ($ln -match '^\|.*\|\s*([0-9]+\.?[0-9]*)\s*\|\s*Done\s*\(Batch\s+(\d+)\)') {
            $score    = [double]$Matches[1]
            $batchTag = [int]$Matches[2]
            if ($score -ge 0 -and $score -le 10) {
                if (-not $batchScores.ContainsKey($batchTag)) {
                    $batchScores[$batchTag] = New-Object System.Collections.Generic.List[double]
                }
                [void]$batchScores[$batchTag].Add($score)
            }
        }
    }

    if ($batchScores.Count -eq 0) {
        $result.Reason = "No completed batches found in index -- skipping drift check"
        return $result
    }

    # ---- Identify recent vs baseline batches -------------------------------
    $sortedBatchNums = $batchScores.Keys | Sort-Object -Descending
    $lastBatchNum = $sortedBatchNums[0]
    $result.LastBatchNumber = $lastBatchNum

    $recentNums   = $sortedBatchNums | Select-Object -First $RecentBatches
    $baselineNums = $sortedBatchNums | Select-Object -Skip $RecentBatches -First $BaselineBatches

    $recentScores = New-Object System.Collections.Generic.List[double]
    foreach ($n in $recentNums) {
        foreach ($s in $batchScores[$n]) { [void]$recentScores.Add($s) }
    }
    $baselineScores = New-Object System.Collections.Generic.List[double]
    foreach ($n in $baselineNums) {
        foreach ($s in $batchScores[$n]) { [void]$baselineScores.Add($s) }
    }

    if ($recentScores.Count -eq 0) {
        $result.Reason = "Recent batch has no scored objects -- skipping drift check"
        return $result
    }

    # Stats
    $recentAvg = ($recentScores | Measure-Object -Average).Average
    $recentMin = ($recentScores | Measure-Object -Minimum).Minimum
    $failsInRecent = @($recentScores | Where-Object { $_ -lt 7.5 }).Count
    $failFraction  = $failsInRecent / [double]$recentScores.Count

    $result.LastBatchAvg    = [math]::Round($recentAvg, 2)
    $result.LastBatchMin    = [math]::Round($recentMin, 2)
    $result.LastBatchScores = $recentScores.ToArray()

    if ($baselineScores.Count -ge 3) {
        $sortedBaseline = $baselineScores | Sort-Object
        $mid = [int]($sortedBaseline.Count / 2)
        $baselineMedian = if ($sortedBaseline.Count % 2 -eq 1) {
            $sortedBaseline[$mid]
        } else {
            ($sortedBaseline[$mid-1] + $sortedBaseline[$mid]) / 2.0
        }
        $result.BaselineMedian  = [math]::Round($baselineMedian, 2)
        $result.BaselineSampleN = $baselineScores.Count
    } else {
        # Insufficient baseline -- skip drift detection but log for observability
        $result.Reason = "Insufficient baseline (only $($baselineScores.Count) scored objects) -- need 3+ to compare. Default batch size."
        Add-DriftHistory -StatePath $statePath -Record @{
            timestamp        = (Get-Date).ToUniversalTime().ToString("o")
            schema           = $SchemaName
            last_batch       = $lastBatchNum
            recent_avg       = $result.LastBatchAvg
            recent_min       = $result.LastBatchMin
            recent_n         = $recentScores.Count
            baseline_median  = -1
            baseline_n       = $baselineScores.Count
            drift_level      = "none"
            next_batch_size  = $result.NextBatchSize
            reason           = $result.Reason
        }
        return $result
    }

    # ---- Drift evaluation --------------------------------------------------
    $absDelta = $baselineMedian - $recentAvg   # positive = recent is worse

    $isMildDrift = ($absDelta -ge $ThrottleAbsThreshold) -or ($failFraction -ge $ThrottleFailFraction)
    $isSevereDrift = $false
    if ($recentAvg -lt $KillAvgThreshold) { $isSevereDrift = $true }
    if ($recentMin -lt 5.0 -and $failFraction -ge 0.75) { $isSevereDrift = $true }

    if ($isSevereDrift) {
        $result.DriftLevel    = "severe"
        $result.NextBatchSize = $ThrottledBatchSize
    } elseif ($isMildDrift) {
        $result.DriftLevel    = "mild"
        $result.NextBatchSize = $ThrottledBatchSize
    } else {
        $result.DriftLevel    = "none"
        $result.NextBatchSize = $DefaultBatchSize
    }

    # ---- Consecutive-drift kill check -------------------------------------
    $consecutiveDrifts = 0
    if ($result.DriftLevel -ne "none") { $consecutiveDrifts = 1 }
    if (Test-Path $statePath) {
        try {
            $history = Get-Content $statePath -ErrorAction SilentlyContinue |
                       ForEach-Object { $_ | ConvertFrom-Json } |
                       Where-Object { $_ -and $_.last_batch -ne $lastBatchNum } |
                       Sort-Object { [int]$_.last_batch } -Descending |
                       Select-Object -First ($KillConsecutiveDrifts - 1)
            foreach ($h in $history) {
                if ($h.drift_level -ne "none") { $consecutiveDrifts++ }
                else { break }
            }
        } catch { }
    }

    if ($consecutiveDrifts -ge $KillConsecutiveDrifts) {
        $result.ShouldKill = $true
        $result.Reason = "KILL: $consecutiveDrifts consecutive drift events. Recent avg=$($result.LastBatchAvg) (baseline median=$($result.BaselineMedian)). Loop is producing degraded output -- stop and investigate."
    } elseif ($isSevereDrift) {
        $result.ShouldKill = $true
        $result.Reason = "KILL: severe drift -- last batch avg ($($result.LastBatchAvg)) below kill threshold ($KillAvgThreshold). Investigate before resuming."
    } elseif ($result.DriftLevel -eq "mild") {
        $result.Reason = ("Mild drift -- recent avg {0} vs baseline median {1} (drop {2:F2}, fails<7.5 = {3:P0}). Throttling next batch to {4}." -f $result.LastBatchAvg, $result.BaselineMedian, $absDelta, $failFraction, $ThrottledBatchSize)
    } else {
        $direction = if ($absDelta -gt 0) { "drop" } else { "lift" }
        $result.Reason = ("Quality steady -- recent avg {0} vs baseline median {1} ({2} {3:F2}). Continuing at default batch size {4}." -f $result.LastBatchAvg, $result.BaselineMedian, $direction, [math]::Abs($absDelta), $DefaultBatchSize)
    }

    # ---- Persist drift history --------------------------------------------
    Add-DriftHistory -StatePath $statePath -Record @{
        timestamp        = (Get-Date).ToUniversalTime().ToString("o")
        schema           = $SchemaName
        last_batch       = $lastBatchNum
        recent_avg       = $result.LastBatchAvg
        recent_min       = $result.LastBatchMin
        recent_n         = $recentScores.Count
        baseline_median  = $result.BaselineMedian
        baseline_n       = $baselineScores.Count
        abs_delta        = [math]::Round($absDelta, 3)
        fail_fraction    = [math]::Round($failFraction, 3)
        drift_level      = $result.DriftLevel
        next_batch_size  = $result.NextBatchSize
        should_kill      = $result.ShouldKill
        reason           = $result.Reason
    }

    return $result
}

function Add-DriftHistory {
    param(
        [Parameter(Mandatory=$true)] [string] $StatePath,
        [Parameter(Mandatory=$true)] [hashtable] $Record
    )
    try {
        $json = ($Record | ConvertTo-Json -Compress -Depth 3)
        Add-Content -Path $StatePath -Value $json -Encoding UTF8
    } catch {
        Write-Warning "Failed to append drift history to $StatePath : $_"
    }
}
