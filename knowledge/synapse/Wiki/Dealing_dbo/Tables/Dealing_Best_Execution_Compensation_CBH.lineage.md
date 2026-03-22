# Column Lineage: Dealing_dbo.Dealing_Best_Execution_Compensation_CBH

**Generated**: 2026-03-21 | **Batch**: 5 | **Writer SP**: SP_Best_Execution
**⚠️ Pipeline status**: POTENTIALLY DECOMMISSIONED — max date 2025-01-11

## Pipeline Summary

```
Dealing_Daily_Slippage_Positions (OverThreshold=1)─┐
Dealing_Daily_Latency_Compensation                 ─┤─► SP_Best_Execution ──► Dealing_Best_Execution_Compensation_CBH
CopyFromLake.PriceLog_History_CurrencyPrice         ─┤   (CBH section,       (DELETE+INSERT by Date)
DWH_dbo.Dim_Position                               ─┤    reads Slippage
Dealing_staging.External_CalendarDB_Market_...     ─┤    then fetches LP
Dealing_staging.etoro_Trade_LiquidityAccounts      ─┘    price at exact time)
```

## Column-Level Lineage

| Column | Source Table | Source Column | Transformation |
|--------|-------------|---------------|----------------|
| Date | @Date parameter | — | Report date |
| PositionID | Dealing_Daily_Slippage_Positions | PositionID | Direct passthrough |
| CID | Dealing_Daily_Slippage_Positions | CID | Direct passthrough |
| InstrumentID | Dealing_Daily_Slippage_Positions | InstrumentID | Direct |
| InstrumentName | Dealing_Daily_Slippage_Positions | InstrumentName | Direct |
| InstrumentTypeID | Dealing_Daily_Slippage_Positions | InstrumentTypeID | Direct |
| InstrumentType | Dealing_Daily_Slippage_Positions | InstrumentType | Direct |
| HedgeServerID | Dealing_Daily_Slippage_Positions | HedgeServerID | Direct |
| MirrorID | Dealing_Daily_Slippage_Positions | MirrorID | Direct |
| IsBuy | Dealing_Daily_Slippage_Positions | IsBuy | Direct |
| OrigIsBuy | Dealing_Daily_Slippage_Positions | OrigIsBuy | Direct |
| ExecutionAmountInUnits | Dealing_Daily_Slippage_Positions | ExecutionAmountInUnits × SplitRatio | Split-adjusted in SP |
| AmountInUnitsDecimal | Dealing_Daily_Slippage_Positions | AmountInUnitsDecimal × SplitRatio | Split-adjusted |
| Occurred | Dealing_Daily_Slippage_Positions | Occurred | Direct |
| EndForexRate | Dealing_Daily_Slippage_Positions | EndForexRate | Direct |
| ConversionRate | Dealing_Daily_Slippage_Positions | ConversionRate | Direct |
| ActionTypeID | Dealing_Daily_Slippage_Positions | ActionTypeID | Direct |
| ActionType | Dealing_Daily_Slippage_Positions | ActionType | Direct |
| IsOpen | Dealing_Daily_Slippage_Positions | IsOpen | Direct |
| Bid | CopyFromLake.PriceLog_History_CurrencyPrice | Bid | At FinalOccurred (EU: LA 54/127; non-EU: general) |
| Ask | CopyFromLake.PriceLog_History_CurrencyPrice | Ask | At FinalOccurred |
| OccurredAtServer | CopyFromLake.PriceLog_History_CurrencyPrice | OccurredAtServer | Price tick server time |
| StopRate | Dealing_Daily_Slippage_Positions | StopRate | Direct |
| LimitRate | Dealing_Daily_Slippage_Positions | LimitRate | Direct |
| ClientViewRate | Dealing_Daily_Slippage_Positions | ClientViewRate | Direct |
| CustomerChosenRate | Dealing_Daily_Slippage_Positions | CustomerChosenRate | Direct |
| SlippageInDollar | Dealing_Daily_Slippage_Positions | SlippageInDollar | Direct |
| slippage % | Dealing_Daily_Slippage_Positions | slippage % | Direct |
| RequestTime | Dealing_Daily_Slippage_Positions | RequestTime | Direct |
| OverThreshold | Dealing_Daily_Slippage_Positions | OverThreshold | Always 1 (filtered at source) |
| OpenSession | Dealing_Daily_Slippage_Positions | OpenSession | Direct |
| Volume | Dealing_Daily_Slippage_Positions | Volume | Direct |
| Regulation | Dealing_Daily_Slippage_Positions | Regulation | Direct |
| PriceRateID | DWH_dbo.Dim_Position | InitForexPriceRateID / EndForexPriceRateID | Open or close rate ID |
| FinalOccurred | CopyFromLake.PriceLog_History_CurrencyPrice | Occurred | COALESCE(PriceOccurred, Occurred) |
| HedgingMode | Dealing_Daily_Slippage_Positions | HedgingMode | Direct (CBH for this table) |
| LiquidityAccountID | Dealing_Daily_Latency_Compensation | LiquidityAccountID | JOIN via PositionID |
| LiquidityAccountName | Dealing_staging.etoro_Trade_LiquidityAccounts | LiquidityAccountName | JOIN via LiquidityAccountID |
| Spread | DWH_dbo.Dim_Position | InitForex_AskSpreaded, InitForex_Ask/Bid, EndForex_Bid/Ask | CBH: (InitForexRate_ToSpread − InitForex_Ask) for buy open; inverse for sell |
| LP_Rate | CopyFromLake.PriceLog_History_CurrencyPrice | Bid / Ask | Bid for buy-close/sell-open; Ask for buy-open/sell-close |
| Percent_Diff | — | (CustomerChosenRate − LP_Rate) / LP_Rate | Computed |
| Compensation_Limit | — | Policy-based cap | Compensation ceiling |
| Compensation | — | MIN(ABS(SlippageInDollar), Compensation_Limit) under policy | Computed; 0 if within policy |
| UpdateDate | GETDATE() | — | Batch timestamp |
| RequestOccurred | DWH_dbo.Dim_Position | RequestOpenOccurred / RequestCloseOccurred | Direct |
| OpenMarketTime | Dealing_staging.External_CalendarDB_Market_MergedDailySchedules | OpenTimeUTC | Exchange open time |
| WithinFirst5Minutes_MarketHours | — | FinalOccurred ≤ OpenMarketTime + 5min | Boolean |
| WithinFirst7Minutes_MarketHours | — | FinalOccurred ≤ OpenMarketTime + 7min | Boolean |

## ETL Pattern

- DELETE WHERE Date=@Date → INSERT DISTINCT
- SP writes HBC table first, then CBH table (sequential in same SP run)
- Input: OverThreshold=1 rows from Dealing_Daily_Slippage_Positions
