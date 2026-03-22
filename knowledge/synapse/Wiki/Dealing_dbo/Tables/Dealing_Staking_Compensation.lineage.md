# Lineage — Dealing_dbo.Dealing_Staking_Compensation

**Writer SP**: `Dealing_dbo.SP_Staking_Emails` (daily, SB_Daily pipeline)
**Write pattern**: DELETE WHERE StakingMonthID = @StakingMonthID, then INSERT from Dealing_Staking_Results

## Source Chain

```
Dealing_dbo.Dealing_Staking_Results (written by SP_Staking in a prior step)
    WHERE ActualCompensationType = 'Cash'
    → StakingMonthID, StakingMonth, StakingYear, CID, InstrumentID, USD_Compensation (cast to StakingRewards_USD)
```

## Column Lineage

| Column | Source | Tier | Notes |
|--------|--------|------|-------|
| StakingMonthID | Dealing_Staking_Results.StakingMonthID | Tier 3 | ⚠️ DATA QUALITY: months 202503 and 202410 stored as 2025030 and 2024100 (7-digit format bug) |
| StakingMonth | Dealing_Staking_Results.StakingMonth | Tier 3 | Month name string |
| StakingYear | Dealing_Staking_Results.StakingYear | Tier 3 | Calendar year |
| CID | Dealing_Staking_Results.CID | Tier 3 | Client ID of the cash compensation recipient |
| InstrumentID | Dealing_Staking_Results.InstrumentID | Tier 3 | Crypto instrument that earned the compensation |
| StakingRewards_USD | CAST(Dealing_Staking_Results.USD_Compensation AS DECIMAL(28,4)) | Tier 3 | USD value of cash compensation paid instead of airdrop |
| UpdateDate | GETDATE() at SP_Staking_Emails execution time | Tier 4 — ETL metadata | ETL run timestamp |

## Trigger Dependency

SP_Staking_Emails runs when Dealing_staging.etoro_Trade_AdminPositionLog contains airdrop results (OpenActionType=11) for the target month AND all results have arrived (last record > 3 hours ago) AND Dealing_Staking_Compensation doesn't yet have that month.
