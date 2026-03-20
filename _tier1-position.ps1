$emdash = [char]0x2014
$tier1 = @{}
$pt = 'Trade.PositionTbl'

# Group A: Core Identity
$tier1['PositionID']          = @($pt, 'Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position.')
$tier1['CID']                 = @($pt, 'Customer ID. References Customer.Customer.')
$tier1['InstrumentID']        = @($pt, 'FK to Trade.Instrument. Financial instrument being traded.')
$tier1['CurrencyID']          = @($pt, 'FK to Dictionary.Currency. Denomination currency for Amount, NetProfit. Must be > 0.')
$tier1['ProviderID']          = @($pt, 'References Trade.Provider. Execution provider (default 1 = TRADONOMI in PositionOpen).')

# Group B: Lifecycle Timestamps
$tier1['OpenOccurred']        = @($pt, 'When position was persisted (mapped from Occurred in production). Default getutcdate().')
$tier1['CloseOccurred']       = @($pt, 'When close was persisted.')
$tier1['RequestOpenOccurred']  = @($pt, 'When the open request arrived at Trading API. Distinct from OpenOccurred (DB insert time).')
$tier1['RequestCloseOccurred'] = @($pt, 'When close request arrived at API.')

# Group C: Financial Metrics
$tier1['Amount']              = @($pt, 'Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents).')
$tier1['AmountInUnitsDecimal'] = @($pt, 'Position size in units/shares. Fractional lots.')
$tier1['InitialAmountCents']  = @($pt, 'Initial amount in cents. Used for ratio calculations.')
$tier1['InitialUnits']        = @($pt, 'Original unit count at open. Used for partial close ratio.')
$tier1['NetProfit']           = @($pt, 'Realized PnL. 0 when open; set on close. In position currency.')
$tier1['Commission']          = @($pt, 'Open commission in dollars. PositionOpen stores @Commission/100 (cents to dollars).')
$tier1['CommissionOnClose']   = @($pt, 'Commission charged on close.')
$tier1['FullCommission']      = @($pt, 'Full commission including spread. PositionOpen stores @FullCommission/100.')
$tier1['FullCommissionOnClose'] = @($pt, 'Full commission on close.')
$tier1['EndOfWeekFee']        = @($pt, 'Overnight/weekend carry fee.')

# Group D: Units
$tier1['LotCountDecimal']     = @($pt, 'Lot count from provider. Used for hedge aggregation and unit-based sizing.')
$tier1['UnitMargin']          = @($pt, 'Margin per unit. From Trade.ProviderToInstrument.')

# Group E: Direction, Leverage, Trade Settings
$tier1['IsBuy']               = @($pt, '1 = Long/Buy (profit when price rises), 0 = Short/Sell.')
$tier1['Leverage']            = @($pt, 'Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type.')
$tier1['CloseOnEndOfWeek']    = @($pt, 'Weekend-close flag. 1 = position auto-closes at end of trading week.')
$tier1['LimitRate']           = @($pt, 'Take-profit rate set at open (or most recent update).')
$tier1['StopRate']            = @($pt, 'Stop-loss rate set at open (or most recent update). Can be updated via PositionChangeLog.')

# Group F: Forex Rates
$tier1['InitForexRate']       = @($pt, 'Opening price rate at position open. Used for PnL calculation.')
$tier1['EndForexRate']        = @($pt, 'Closing rate at position close. NULL for open positions.')
$tier1['LastOpConversionRate'] = @($pt, 'Conversion rate for last operation.')
$tier1['InitConversionRate']  = @($pt, 'Currency conversion rate at open.')
$tier1['SpreadedPipBid']      = @($pt, 'Bid rate with spread at open. From Trade.CurrencyPrice/spread config.')
$tier1['SpreadedPipAsk']      = @($pt, 'Ask rate with spread at open.')

# Group G: Price Rate IDs
$tier1['InitForexPriceRateID'] = @($pt, 'FK to price log table -- the specific price rate record at open.')
$tier1['EndForexPriceRateID'] = @($pt, 'Price rate ID at close.')
$tier1['LastOpPriceRateID']   = @($pt, 'Last operation price rate ID.')
$tier1['LastOpPriceRate']     = @($pt, 'Last operation price. Updated on partial close, dividend, etc.')
$tier1['OpenMarketPriceRateID'] = @($pt, 'Market price rate ID at open.')
$tier1['CloseMarketPriceRateID'] = @($pt, 'Market price rate ID at close.')
$tier1['InitConversionRateID'] = @($pt, 'Conversion rate record ID at open.')

# Group H: Execution IDs
$tier1['InitExecutionID']     = @($pt, 'Execution record ID at open.')
$tier1['EndExecutionID']      = @($pt, 'Execution record ID at close. NULL for open positions.')

# Group L: Markup and Spread
$tier1['OpenMarketSpread']    = @($pt, 'Spread at open.')
$tier1['CloseMarketSpread']   = @($pt, 'Spread at close.')
$tier1['CloseMarkupOnOpen']   = @($pt, 'Close markup projected at open.')
$tier1['OpenMarkup']          = @($pt, 'Markup at open.')
$tier1['CloseMarkup']         = @($pt, 'Markup at close.')
$tier1['SpreadedCommission']  = @($pt, 'Spread-related commission component.')

# Group M: Social Trading
$tier1['MirrorID']            = @($pt, 'FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position.')
$tier1['HedgeID']             = @($pt, 'FK to Trade.Hedge. Broker executed hedge. NULL until hedge is opened.')
$tier1['HedgeServerID']       = @($pt, 'FK to Trade.HedgeServer. Hedge server managing this position.')
$tier1['ParentPositionID']    = @($pt, 'Copy-trade parent. 0/1 = root. Positive = child of referenced position.')
$tier1['OrigParentPositionID'] = @($pt, 'Original parent before any detachment.')
$tier1['TreeID']              = @($pt, 'Links to Trade.PositionTreeInfo. Root: TreeID=PositionID. Children: root PositionID. Demo: negative.')
$tier1['IsOpenOpen']          = @($pt, 'Open-on-open copy behavior. From Mirror.')

# Group N: Partial Close and ReOpen
$tier1['ReopenForPositionID'] = @($pt, 'When position was reopened: references the erroneously closed PositionID.')

# Group O: Settlement and Redemption
$tier1['IsSettled']           = @($pt, 'LEGACY: 1 = real stock, 0 = CFD. NOT settlement complete. Predates SettlementTypeID.')
$tier1['RedeemStatus']        = @($pt, 'Redemption state. Billing.Redeem integration.')
$tier1['RedeemID']            = @($pt, 'Billing.Redeem reference when position closed via redeem.')

# Group P: Close Reason, Order
$tier1['OrderID']             = @($pt, 'FK to Trade.Orders. Originating order. NULL for corporate action/dividend positions.')
$tier1['ExitOrderID']         = @($pt, 'Order that closed the position (exit order).')
$tier1['OrderType']           = @($pt, 'Dictionary.OrderType at open. 1=OpenTrade, 13=EntryOrder, 16=EntryOrderByUnits, etc.')
$tier1['ExitOrderType']       = @($pt, 'Order type of the exit order. Dictionary.OrderType.')
$tier1['ClosePositionReasonID'] = @($pt, 'Close reason mapped from ActionType. 0=Customer, 1=Stop Loss, 5=Take Profit, 9=Hierarchical Close.')
$tier1['OpenPositionReasonID'] = @($pt, 'Open reason mapped from OpenActionType. 0=Customer, 1=Hierarchical Open, 2=Reopen, 3=Open Open, 13=ACATS_IN.')

# Group V: Settlement Type
$tier1['SettlementTypeID']    = @($pt, 'Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled.')

# Group W
$tier1['IsComputeForHedge']   = @($pt, '1 = include in hedge exposure calculation, 0 = exclude.')

# Group U: Versions
$tier1['PnLVersion']          = @($pt, 'PnL calculation version.')

# Group X: Taxes and Fees
$tier1['OpenTotalTaxes']      = @($pt, 'Taxes at open.')
$tier1['CloseTotalTaxes']     = @($pt, 'Taxes at close.')
$tier1['OpenTotalFees']       = @($pt, 'Fees at open.')
$tier1['CloseTotalFees']      = @($pt, 'Fees at close.')

# ── Process file ──
$path = 'knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md'
$content = Get-Content $path -Encoding UTF8
$output = [System.Collections.ArrayList]@()
$t1Count = 0
$t2Count = 0
$t4Count = 0
$t1Names = [System.Collections.ArrayList]@()
$t2Names = [System.Collections.ArrayList]@()

foreach ($line in $content) {
    $trimmed = $line.Trim()
    if ($trimmed -match '^\|\s*(\d+)\s*\|\s*([A-Za-z0-9_]+)\s*\|') {
        $rowNum = $Matches[1]
        $colName = $Matches[2]
        
        if ($tier1.ContainsKey($colName)) {
            $src = $tier1[$colName][0]
            $desc = $tier1[$colName][1]
            $suffix = "(Tier 1 $emdash $src)"
            $parts = $trimmed -split '\|'
            $lastIdx = $parts.Count - 2
            $parts[$lastIdx] = " $desc $suffix "
            $newLine = $parts -join '|'
            [void]$output.Add($newLine)
            $t1Count++
            [void]$t1Names.Add("  T1 #$rowNum $colName")
            continue
        } else {
            if ($trimmed -match '\(Tier 2') { $t2Count++ }
            elseif ($trimmed -match '\(Tier 4') { $t4Count++ }
            [void]$t2Names.Add("  kept #$rowNum $colName")
        }
    }
    [void]$output.Add($line)
}

# Update footer
for ($i = $output.Count - 1; $i -ge 0; $i--) {
    if ($output[$i] -match '^\*Tiers:') {
        $remaining = $t2Count + $t4Count
        $output[$i] = "*Tiers: $t1Count T1, $t2Count T2, 0 T3, $t4Count T4, 0 T5 | Phases: 1,2,3,5,7,8,9,9B,10,10.5,13,11*"
        break
    }
}

# Also update the "No upstream production wiki" note
for ($i = 0; $i -lt $output.Count; $i++) {
    if ($output[$i] -match 'No upstream production wiki available') {
        $output[$i] = "Note: Upstream production wiki available for Trade.PositionTbl. Columns with direct passthrough from staging get Tier 1. ETL-computed and PriceLog-enriched columns get Tier 2."
        break
    }
}

$output | Set-Content $path -Encoding UTF8
Write-Host "Dim_Position updated: $t1Count Tier 1, $t2Count Tier 2, $t4Count Tier 4"
Write-Host ""
Write-Host "=== Tier 1 (from Trade.PositionTbl wiki) ==="
$t1Names | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "=== Kept as-is (Tier 2/4) ==="
$t2Names | ForEach-Object { Write-Host $_ }
