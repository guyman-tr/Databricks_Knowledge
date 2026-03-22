# Lineage — Dealing_dbo.Dealing_Staking_Club_US

**Writer SP**: `Dealing_dbo.SP_Staking_US` (daily at 11:00 AM, ProcessType 3 SQL&TIME)
**Write pattern**: DELETE WHERE StakingMonthID = @StakingMonthID, then INSERT from `#1USD_Holdings_Threshold_US`

## Source Chain

```
Dealing_staging.Fivetran_google_sheets_platform_rewards (WHERE is_us = 1)
    → #Staking_Parameters (US-eligible rewards only: ADA, SOL, ETH)
    → StakingMonthID, StakingMonth, StakingYear, Currency, InstrumentID

BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Customer (US clients: RegulationID IN (6,7,8))
    → #EligiblePool_US → #PositionData_US → #CIDShare_US → #Final_US
    → #Under_Over_US → #1USD_Holdings_Threshold_US

DWH_dbo.Dim_PlayerLevel → PlayerLevel
Dealing_dbo.Dealing_Staking_Parameters → IntroDays
```

## Column Lineage

| Column | Source | Tier | Notes |
|--------|--------|------|-------|
| StakingMonthID | Fivetran_google_sheets_platform_rewards.staking_month_id (is_us=1) | Tier 3 | US rewards only |
| StakingMonth | DATENAME(MONTH, StakingEndDate) | Tier 3 | Month name string |
| StakingYear | YEAR(StakingEndDate) | Tier 3 | Calendar year |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL.InstrumentID (US-filtered) | Tier 3 | Crypto instrument FK |
| Currency | Fivetran_google_sheets_platform_rewards.currency (is_us=1) | Tier 3 | Ticker (ADA, SOL, ETH for US) |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel.Name | Tier 1 — DWH_dbo.Dim_PlayerLevel | Loyalty tier name |
| Avg_Daily_Holdings_Threshold | `((under_holdings + over_holdings) / 2) / TotalStakingDays` from #1USD_Holdings_Threshold_US | Tier 3 | Same algorithm as non-US variant |
| UpdateDate | GETDATE() at SP_Staking_US execution time | Tier 4 — ETL metadata | ETL run timestamp |
