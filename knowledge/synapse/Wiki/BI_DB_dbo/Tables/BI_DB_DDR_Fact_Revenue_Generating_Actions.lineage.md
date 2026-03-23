# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions

## Summary

Granular DDR fact for **revenue-generating actions** (commissions, fees, spreads, staking, options PFOF, etc.). Built by `SP_DDR_Fact_Revenue_Generating_Actions(@date)` from many `BI_DB_dbo.Function_Revenue_*` table-valued functions, dimension lookups, external parquet staging, and `BI_DB_dbo.Dim_Revenue_Metrics` for metric IDs and `IncludedInTotalRevenue` classification.

## Column Mapping

| DWH Column | Primary Source | Transform | Notes |
|------------|----------------|-----------|-------|
| DateID | #revenue / #staking / #optionsalltime | passthrough or computed | Main load uses `@date` → YYYYMMDD; staking uses lagged month logic |
| Date | Parameter `@date` or function output | `CONVERT` / passthrough | Main INSERT sets `[Date] = @date`; options pass-through from function |
| RealCID | Revenue functions / `CID` | passthrough | Customer key (real customer) |
| ActionTypeID | Functions, `DWH_dbo.Dim_ActionType`, or NULL | aggregated | Often NULL for fee buckets; commissions join `Dim_ActionType` |
| ActionType | `Dim_ActionType.Name` or literal | union of many branches | e.g. Rollover, TicketFee, Staking |
| InstrumentTypeID | Position/instrument context | ISNULL → -1 in INSERT | From functions or fixed literals per metric |
| IsSettled | Position-level functions | ISNULL → -1 | |
| IsCopy | MirrorID / functions | ISNULL → -1 | Copy-trading flag |
| Metric | Branch-specific name | string | e.g. FullCommission, SDRT, StakingLagOneMonth |
| Amount | SUM/COUNT from functions | numeric | Decimal precision in table |
| CountTransactions | counts / sums | ISNULL → 0 | Staking/options may be NULL before coalesce |
| IncludedInTotalRevenue | #revenue then `Dim_Revenue_Metrics` join | **drm.IncludedInTotalRevenue** overrides on INSERT | SP also forces SDRT/CryptoToFiat updates |
| CountAsActiveTrade | CASE on ActionTypeID | ISNULL → 0 | e.g. FullCommission for ActionTypeID 1,39 non-airdrop |
| UpdateDate | — | `GETDATE()` | |
| IsBuy | functions / CASE | ISNULL → -1 | Dividend sign logic applied in UPDATE |
| IsLeveraged | `Leverage > 1` | ISNULL → -1 | |
| IsFuture | instruments / functions | ISNULL → -1 | |
| IsCopyFund | `BI_DB_CopyFund_Positions` | ISNULL → -1 | |
| IsOpenedFromIBAN | parquet + `Dim_Position` | 0/1 then ISNULL → -1 | Positions opened via IBAN |
| IsClosedToIBAN | parquet + `Dim_Position` | same pattern | |
| IsRecurring | recurring positions parquet | same | |
| IsAirDrop | functions | ISNULL → -1 | |
| IsSQF | instrument snapshot / functions | ISNULL → -1 | Spot Quoted Futures |
| RevenueMetricID | `Dim_Revenue_Metrics` / hardcoded (staking, options) | JOIN on `Metric` | Staking=12, Options=18 |
| RevenueMetricCategoryID | `Dim_Revenue_Metrics` / hardcoded | | |
| IsMarginTrade | functions | ISNULL → -1 | |
| IsC2P | `V_C2P_Positions` | ISNULL → -1 | Copy to Portfolio |

## ETL Pipeline

```
SP_DDR_Fact_Revenue_Generating_Actions(@date)
  ├─ Staging: #c2p ← V_C2P_Positions
  ├─ Staging: #openedFromIban / #closedToIban ← external parquet + DWH_dbo.Dim_Position
  ├─ Staging: #isRecurring ← External recurring positions parquet
  ├─ Fee slices: #rollovers, #dividends, #sdrt, #ticketFee, #ticketFeeByPercent
  │     ← Function_Revenue_RolloverFee, _Dividend, _SDRT, _TicketFee, _TicketFeeByPercent
  ├─ Commissions: #fullcommissions, #commissions ← Function_Revenue_FullCommissions, _Commissions
  ├─ Other: #adminfee, #spotadjust ← Function_Revenue_AdminFee, _SpotAdjustFee
  ├─ #overnights ← aggregates above + BI_DB_CopyFund_Positions
  ├─ #revenue ← large UNION ALL (commissions, overnight metrics, cashout, conversion, dormant,
  │     interest, transfer coin, admin, spot adjust, share lending, crypto-fiat, …)
  ├─ Post-UPDATE rules on #revenue (SDRT IncludedInTotalRevenue=0, C2F null sentinels, etc.)
  ├─ #staking ← Function_Revenue_StakingFee (month lag) — RevenueMetricID 12
  ├─ #optionsalltime ← Function_Revenue_OptionsPlatform (wide date range) — RevenueMetricID 18
  ├─ DELETE WHERE DateID = @dateID → INSERT from #revenue + Dim_Revenue_Metrics (Metric join)
  ├─ DELETE RevenueMetricID = 18 → INSERT options rows from #optionsalltime
  └─ DELETE staking month-range + INSERT from #staking (retroactive staking reruns)
```

## Source Objects (logical)

| Source | Role |
|--------|------|
| BI_DB_dbo.Function_Revenue_* (many) | Core revenue amounts and position attributes per metric family |
| DWH_dbo.Dim_ActionType | Action type names for commission rows |
| DWH_dbo.Dim_Instrument | IsFuture, etc. for admin/spot adjust |
| DWH_dbo.Dim_Position | Open/Close DateID for IBAN parquet filters |
| BI_DB_dbo.Dim_Revenue_Metrics | `RevenueMetricID`, `RevenueMetricCategoryID`, `IncludedInTotalRevenue` by `Metric` |
| BI_DB_dbo.V_C2P_Positions | IsC2P |
| BI_DB_dbo.BI_DB_CopyFund_Positions | IsCopyFund |
| External parquet (opened/closed IBAN, recurring) | IBAN and recurring flags |
| BI_DB_dbo.Function_Revenue_StakingFee | Staking lagged rows |
| BI_DB_dbo.Function_Revenue_OptionsPlatform | Options / PFOF (second load pass) |

## Consumers

| Consumer | Usage |
|----------|--------|
| BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown (view) | DDR revenue breakdown |
| BI_DB_dbo.Function_Revenue_Total | Aggregated revenue from this fact |
| BI_DB_dbo.SP_RevenueForum | Forum / reporting |
