# Lineage — Dealing_dbo.Dealing_Staking_Emails_New

**Writer SP**: `Dealing_dbo.SP_Staking_Emails` (daily, SB_Daily pipeline — runs same session as Dealing_Staking_Compensation)
**Write pattern**: DELETE WHERE StakingMonthID = @StakingMonthID, then INSERT from #Emails

## Source Chain

```
Dealing_dbo.Dealing_Staking_Results r
    → StakingMonthID, StakingYear, StakingMonth, GCID, InstrumentID, Currency
    → Units (from Dealing_Staking_Summary s: s.RewardsToDistribute)
    → MPercentage (from s.EtoroYield)
    → CPercentage (r.RevShare)
    → Reward (r.ActualAirdropUnits or r.Client_Airdrop)
    → ClubTier (DWH_dbo.Dim_PlayerLevel via r)
    → Mailing_Group (CASE on r.IsAirdropSuccess, FailReasonID, OriginalCompensationType, CountryID, PlayerLevelID)

DWH_dbo.Fact_SnapshotCustomer fsc JOIN DWH_dbo.Dim_Range dr (range-based join for current snapshot)
    → CountryID, LanguageID, PlayerLevelID
DWH_dbo.Dim_Country → Country
DWH_dbo.Dim_Language → Language
DWH_dbo.Dim_PlayerLevel dpl → ClubTier name
```

## Column Lineage

| Column | Source | Tier | Notes |
|--------|--------|------|-------|
| StakingMonthID | Dealing_Staking_Results.StakingMonthID | Tier 3 | ⚠️ DATA QUALITY: same 2025030/2024100 bug as Dealing_Staking_Compensation |
| StakingYear | Dealing_Staking_Results.StakingYear | Tier 3 | |
| StakingMonth | Dealing_Staking_Results.StakingMonth | Tier 3 | |
| GCID | Dealing_Staking_Results.GCID | Tier 3 | Global client ID (not CID) |
| Country | DWH_dbo.Dim_Country.Name via Fact_SnapshotCustomer | Tier 1 — DWH_dbo.Dim_Country | Client's registered country name |
| Language | DWH_dbo.Dim_Language.Name via Fact_SnapshotCustomer | Tier 1 — DWH_dbo.Dim_Language | Client's preferred language |
| InstrumentID | Dealing_Staking_Results.InstrumentID | Tier 3 | |
| Currency | Dealing_Staking_Results.Currency | Tier 3 | |
| Units | Dealing_Staking_Summary.RewardsToDistribute CAST DECIMAL(28,0) | Tier 3 | Total pool units for this instrument/month |
| MPercentage | Dealing_Staking_Summary.EtoroYield CAST DECIMAL(28,4) | Tier 3 | Network-reported yield % |
| CPercentage | Dealing_Staking_Results.RevShare CAST DECIMAL(28,2) | Tier 3 | Client's revenue share fraction (0.45–0.90) |
| Reward | ISNULL(ActualAirdropUnits, Client_Airdrop) CAST DECIMAL(28,4) | Tier 3 | Actual units received (actual overrides planned if available) |
| ClubTier | DWH_dbo.Dim_PlayerLevel.Name | Tier 1 — DWH_dbo.Dim_PlayerLevel | Tier name |
| Mailing_Group | CASE expression on IsAirdropSuccess/FailReasonID/OriginalCompensationType/CountryID/PlayerLevelID | Tier 3 | Email template selector |
| UpdateDate | GETDATE() | Tier 4 — ETL metadata | |
