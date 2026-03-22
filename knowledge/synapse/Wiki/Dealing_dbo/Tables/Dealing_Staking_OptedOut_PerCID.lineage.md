# Lineage — Dealing_dbo.Dealing_Staking_OptedOut_PerCID

**Writer SP**: `Dealing_dbo.SP_Staking_DailyPool` (daily, SB_Daily pipeline — co-written with Dealing_Staking_DailyPool and Dealing_Staking_OptedOut)
**Write pattern**: DELETE WHERE Date = @Date, then INSERT from #OptedOut_PerCID

## Source Chain

```
BI_DB_dbo.BI_DB_PositionPnL (AmountInUnitsDecimal, InstrumentID, DateID, CID)
    filtered by: intro period (IntroDays elapsed), eligible instruments, non-US
    → #OpenPositions → #OptedOut_PerCID (per-client)

DWH_dbo.Dim_Customer → GCID, Regulation
Dealing_staging.Fivetran_google_sheets_* (opt-in/waiver tables) → IsOptedIn
DWH_dbo.Dim_Country → Country
USD exchange rate → USD_Rate
Dealing_dbo.Dealing_Staking_Parameters → IntroDays (eligibility filter)
```

## Column Lineage

| Column | Source | Tier | Notes |
|--------|--------|------|-------|
| Date | @Date SP parameter | Tier 3 | Daily snapshot |
| CID | BI_DB_dbo.BI_DB_PositionPnL.CID | Tier 3 | Trading account ID |
| GCID | DWH_dbo.Dim_Customer.GCID | Tier 1 — DWH_dbo.Dim_Customer | Global client ID |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL.InstrumentID | Tier 3 | |
| Currency | Fivetran_google_sheets_platform_rewards.currency | Tier 3 | |
| USD_Rate | External rate source | Tier 3 | Spot rate at run time |
| Regulation | DWH_dbo.Dim_Customer regulation name | Tier 1 — DWH_dbo | |
| EligibleUnits | SUM(AmountInUnitsDecimal) for this CID/InstrumentID | Tier 3 | |
| EligibleValue | EligibleUnits × USD_Rate | Tier 3 | |
| IsOptedIn | 1 if client opted in via waiver system, 0 if opted out | Tier 3 | |
| UpdateDate | GETDATE() | Tier 4 — ETL metadata | |
| Country | DWH_dbo.Dim_Country.Name | Tier 1 — DWH_dbo.Dim_Country | |
