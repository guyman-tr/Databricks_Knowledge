$emdash = [char]0x2014
$path = 'knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md'
$content = Get-Content $path -Encoding UTF8
$output = [System.Collections.ArrayList]@()

$eod = 'Trade.OpenPositionEndOfDay'
$pt  = 'Trade.PositionTbl'

$fixes = @{}
# Tier 1 from Trade.OpenPositionEndOfDay (staging view) - columns I missed
$fixes['PnLInDollars']                 = @($eod, 'Max-rate PnL in dollars. From Trade.FnCalculatePnLWrapper using the max-date market rate. Represents unrealized profit/loss at the highest available price timestamp.')
$fixes['CurrentCalculationRate']       = @($eod, 'The max-date closing rate used for PnL calculation. From Trade.FnCalculatePnLWrapper. The bid or ask price selected based on IsBuy and IsRealPosition.')
$fixes['CurrentConversionRate']        = @($eod, 'Currency conversion rate at end-of-day for the max-rate PnL. Computed from end-of-day prices using the conversion instrument pair, direction, and settlement type.')
$fixes['Close_PnLInDollars']           = @($eod, 'Official closing-rate PnL in dollars. From Trade.FnCalculatePnLWrapper using the Close_* prices. The regulated end-of-day position value.')
$fixes['Close_CalculationRate']        = @($eod, 'Official closing rate used for close PnL. Selected from Close_Bid/Ask/Spreaded based on direction and settlement.')
$fixes['Close_ConversionRate']         = @($eod, 'Conversion rate at official close. Same calculation as CurrentConversionRate but at the closing price point.')
$fixes['Close_PriceType']             = @($eod, 'Price type indicator for the closing price. From History.CurrencyPriceMaxDateClosingPriceWithSplitView.PriceType.')
$fixes['EstimateCloseFeeForCFD']       = @($eod, 'Estimated close fee for CFD positions at end-of-day rates. From Trade.FnGetCloseFee using max-rate closing rate and conversion rate.')
$fixes['EstimateCloseFeeOnOpen']       = @($eod, 'Estimated close fee calculated based on position open parameters. From Trade.FnGetCloseFeeOnOpen using OpenTotalFees, InitialLotCount, IsBuy, OpenMarketSpread, units.')
$fixes['EstimateCloseFeeOnOpenByUnits'] = @($eod, 'Estimated close fee per unit, calculated from open parameters. From Trade.FnGetCloseFeeOnOpen. Alternative fee calculation method based on unit count.')

# Tier 1 + DWH note for columns that are passthrough but adjusted by DWH SP
$fixes['CommissionOnClose']            = @($pt,  'Commission charged on close. DWH note: adjusted by SP_Dim_Position when position is reopened; CommissionOnCloseOrig stores the pre-adjustment value.')
$fixes['FullCommissionOnClose']        = @($pt,  'Full commission on close. DWH note: adjusted by SP_Dim_Position when position is reopened; FullCommissionOnCloseOrig stores the pre-adjustment value.')

$upgradedCount = 0
$upgradedNames = [System.Collections.ArrayList]@()

foreach ($line in $content) {
    $trimmed = $line.Trim()
    if ($trimmed -match '^\|\s*(\d+)\s*\|\s*([A-Za-z0-9_]+)\s*\|') {
        $rowNum = $Matches[1]
        $colName = $Matches[2]
        if ($fixes.ContainsKey($colName)) {
            $src = $fixes[$colName][0]
            $desc = $fixes[$colName][1]
            $suffix = "(Tier 1 $emdash $src)"
            $parts = $trimmed -split '\|'
            $lastIdx = $parts.Count - 2
            $parts[$lastIdx] = " $desc $suffix "
            [void]$output.Add(($parts -join '|'))
            $upgradedCount++
            [void]$upgradedNames.Add("  upgraded #$rowNum $colName <- $src")
            continue
        }
    }
    [void]$output.Add($line)
}

# Recount all tiers
$t1 = 0; $t2 = 0; $t4 = 0
foreach ($line in $output) {
    if ($line -match '^\|' -and $line -match '\(Tier 1') { $t1++ }
    elseif ($line -match '^\|' -and $line -match '\(Tier 2') { $t2++ }
    elseif ($line -match '^\|' -and $line -match '\(Tier 4') { $t4++ }
}

# Update footer
for ($i = $output.Count - 1; $i -ge 0; $i--) {
    if ($output[$i] -match '^\*Tiers:') {
        $output[$i] = "*Tiers: $t1 T1, $t2 T2, 0 T3, $t4 T4, 0 T5 | Phases: 1,2,3,5,7,8,9,9B,10,10.5,13,11*"
        break
    }
}

# Update the note about upstream wikis
for ($i = 0; $i -lt $output.Count; $i++) {
    if ($output[$i] -match 'Upstream production wiki available for Trade.PositionTbl') {
        $output[$i] = "Note: Upstream production wikis available for Trade.PositionTbl and Trade.OpenPositionEndOfDay. Columns with direct passthrough or view-computed staging get Tier 1. ETL-computed and PriceLog-enriched columns get Tier 2."
        break
    }
}

$output | Set-Content $path -Encoding UTF8
Write-Host "Dim_Position fix2: $upgradedCount columns upgraded"
Write-Host "New totals: $t1 T1, $t2 T2, $t4 T4"
Write-Host ""
$upgradedNames | ForEach-Object { Write-Host $_ }
