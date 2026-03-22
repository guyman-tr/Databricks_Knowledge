# Lineage — Dealing_dbo.Dealing_Staking_Club

**Writer SP**: `Dealing_dbo.SP_Staking` (daily, SB_Daily pipeline)
**Write pattern**: DELETE WHERE StakingMonthID = @StakingMonthID, then INSERT from `#1USD_Holdings_Threshold`

## Source Chain

```
Dealing_staging.Fivetran_google_sheets_platform_rewards
    → #Staking_Parameters (staking period dates, TotalStakingDays, IntroDays)
    → StakingMonthID, StakingMonth, StakingYear, Currency, InstrumentID

BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Customer + #Staking_Parameters
    → #EligiblePool (eligibility filtering by regulation/country)
    → #PositionData (units × eligible days)
    → #CIDShare (per-CID holdings and USD compensation)
    → #Final (all eligible clients with computed staking rewards)
    → #Under_Over (CIDs just below/above $1 USD compensation boundary)
    → #1USD_Holdings_Threshold (interpolated threshold per PlayerLevel/InstrumentID)

DWH_dbo.Dim_PlayerLevel
    → PlayerLevel (tier name)

Dealing_dbo.Dealing_Staking_Parameters
    → IntroDays (intro period by instrument)
```

## Column Lineage

| Column | Source | Tier | Notes |
|--------|--------|------|-------|
| StakingMonthID | #Staking_Parameters.StakingMonthID ← Dealing_staging.Fivetran_google_sheets_platform_rewards.staking_month_id | Tier 3 | YYYYMM integer |
| StakingMonth | #Staking_Parameters.StakingMonth (DATENAME(MONTH, StakingEndDate)) | Tier 3 | Month name string |
| StakingYear | #Staking_Parameters.StakingYear (YEAR(StakingEndDate)) | Tier 3 | Calendar year |
| InstrumentID | #1USD_Holdings_Threshold.InstrumentID ← BI_DB_dbo.BI_DB_PositionPnL.InstrumentID | Tier 3 | Crypto instrument FK |
| Currency | #1USD_Holdings_Threshold.Currency ← Fivetran_google_sheets_platform_rewards.currency | Tier 3 | Crypto ticker symbol |
| PlayerLevel | #1USD_Holdings_Threshold.PlayerLevel ← DWH_dbo.Dim_PlayerLevel.Name | Tier 1 — DWH_dbo.Dim_PlayerLevel | Loyalty tier name |
| Avg_Daily_Holdings_Threshold | `((uo1.[Units*Eligible_Days] + uo.[Units*Eligible_Days]) / 2) / TotalStakingDays` | Tier 3 | Computed: interpolated avg daily units from #Under_Over boundary CIDs |
| UpdateDate | GETDATE() at SP execution time | Tier 4 — ETL metadata | ETL run timestamp |
