# Lineage — Dealing_dbo.Dealing_Staking_Emails_US

**Writer SP**: `Dealing_dbo.SP_Staking_Emails_US` (daily, SB_Daily pipeline)
**Write pattern**: DELETE WHERE StakingMonthID = @StakingMonthID, then INSERT from #Emails_US

## Source Chain

```
Dealing_dbo.Dealing_Staking_Results_US r (US clients only)
Dealing_dbo.Dealing_Staking_Summary_US s
DWH_dbo.Fact_SnapshotCustomer fsc JOIN DWH_dbo.Dim_Range dr
DWH_dbo.Dim_Country → Country
DWH_dbo.Dim_Language → Language
DWH_dbo.Dim_PlayerLevel dpl → ClubTier
```

## Column Lineage

Identical to Dealing_Staking_Emails_New — see that table's lineage. All columns have same sources, filtered to US-regulated clients.

| Notable Difference | Details |
|---|---|
| No malformed IDs | US SP was written after the LEFT(7) bug was fixed |
| Smaller scope | Only 3 US instruments (ADA, SOL, ETH); no SUI in email list |
