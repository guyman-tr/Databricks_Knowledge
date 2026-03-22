# Lineage — Dealing_dbo.Dealing_Staking_Compensation_US

**Writer SP**: `Dealing_dbo.SP_Staking_Emails_US` (daily, SB_Daily pipeline)
**Write pattern**: DELETE WHERE StakingMonthID = @StakingMonthID, then INSERT from Dealing_Staking_Results_US

## Source Chain

```
Dealing_dbo.Dealing_Staking_Results_US (written by SP_Staking_US)
    WHERE ActualCompensationType = 'Cash'
    → StakingMonthID, StakingMonth, StakingYear, CID, InstrumentID, USD_Compensation
```

## Column Lineage

| Column | Source | Tier | Notes |
|--------|--------|------|-------|
| StakingMonthID | Dealing_Staking_Results_US.StakingMonthID | Tier 3 | YYYYMM format, Oct 2025 onward for US |
| StakingMonth | Dealing_Staking_Results_US.StakingMonth | Tier 3 | Month name |
| StakingYear | Dealing_Staking_Results_US.StakingYear | Tier 3 | Calendar year |
| CID | Dealing_Staking_Results_US.CID | Tier 3 | US client receiving cash compensation |
| InstrumentID | Dealing_Staking_Results_US.InstrumentID | Tier 3 | Crypto instrument FK (ADA, SOL, ETH for US) |
| StakingRewards_USD | CAST(USD_Compensation AS DECIMAL(28,4)) | Tier 3 | USD value of cash compensation |
| UpdateDate | GETDATE() | Tier 4 — ETL metadata | SP_Staking_Emails_US execution timestamp |
