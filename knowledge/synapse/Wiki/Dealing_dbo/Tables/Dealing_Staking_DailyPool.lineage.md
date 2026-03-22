# Lineage — Dealing_dbo.Dealing_Staking_DailyPool

**Writer SP**: `Dealing_dbo.SP_Staking_DailyPool` (daily, SB_Daily pipeline)
**Write pattern**: DELETE WHERE Date = @Date, then INSERT from #DailyPool JOIN #AvgDailyPool

## Source Chain

```
BI_DB_dbo.BI_DB_PositionPnL (AmountInUnitsDecimal, DateID, InstrumentID)
    + eligibility filtering (regulation, opted-in status, intro days)
    → #OpenPositions (eligible staking positions for @Date)
    → #DailyPool: SUM(AmountInUnitsDecimal) per (DateID, InstrumentID, Currency) = DailyTotalStakingPool
    → #AvgDailyPool: AVG(TotalUnits) across all dates = Avg_DailyTotalStakingPool

Dealing_staging.Fivetran_google_sheets_platform_rewards → #Staking_Parameters (currency, instrument, period)
Dealing_dbo.Dealing_Staking_Parameters → LiquidityBuffer, IntroDays
DWH_dbo.Dim_Customer → GCID, RegulationID (for eligibility)
```

## Column Lineage

| Column | Source | Tier | Notes |
|--------|--------|------|-------|
| Date | @Date parameter (run date - 1 day typically) | Tier 3 | Daily ETL run date |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL.InstrumentID | Tier 3 | FK to Dim_Instrument |
| Currency | Fivetran_google_sheets_platform_rewards.currency | Tier 3 | Crypto ticker |
| DailyTotalStakingPool | SUM(BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal) for eligible opted-in clients | Tier 3 | Total crypto units in staking pool this day |
| Avg_DailyTotalStakingPool | AVG(DailyTotalStakingPool) across all stored dates for this instrument | Tier 3 | Running average pool size — key input to SP_Staking |
| UpdateDate | GETDATE() | Tier 4 — ETL metadata | SP execution timestamp |
