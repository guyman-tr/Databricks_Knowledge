# Lineage — Dealing_dbo.Dealing_Staking_DailyPool_US

**Writer SP**: `Dealing_dbo.SP_Staking_DailyPool_US` (daily at 11:00 AM, ProcessType 3 SQL&TIME)
**Write pattern**: DELETE WHERE Date = @Date, then INSERT from #DailyPool_US JOIN #AvgDailyPool_US

## Source Chain

```
BI_DB_dbo.BI_DB_PositionPnL (US clients: RegulationID IN (6,7,8))
    filtered to eligible US staking instruments (ADA, SOL, ETH, SUI)
    → #OpenPositions_US → #DailyPool_US (SUM AmountInUnitsDecimal per date/instrument)
    → #AvgDailyPool_US (AVG TotalUnits across dates)

Dealing_staging.Fivetran_google_sheets_platform_rewards (is_us=1) → #Staking_Parameters_US
DWH_dbo.Dim_Customer → US RegulationID
Dealing_dbo.Dealing_Staking_Parameters → IntroDays, LiquidityBuffer
```

## Column Lineage

| Column | Source | Tier | Notes |
|--------|--------|------|-------|
| Date | SP @Date parameter | Tier 3 | Daily from 2025-08-20 |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL.InstrumentID (US) | Tier 3 | ADA/SOL/ETH/SUI |
| Currency | Fivetran_google_sheets_platform_rewards (is_us=1) | Tier 3 | Ticker |
| DailyTotalStakingPool | SUM(AmountInUnitsDecimal) for US opted-in eligible | Tier 3 | US-only pool |
| Avg_DailyTotalStakingPool | AVG(DailyTotalStakingPool) over stored dates | Tier 3 | Used by SP_Staking_US |
| UpdateDate | GETDATE() | Tier 4 — ETL metadata | SP execution timestamp |
