# BI_DB_dbo.BI_DB_ClubUsersDataRemarketingGoogle — Column Lineage

> Generated: 2026-04-23 | Batch 71

## Object Metadata

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object Type | Table |
| Writer SP | SP_ClubUsersDataRemarketingGoogle |
| Load Pattern | TRUNCATE + INSERT (daily full refresh) |
| Population | Club members only (PlayerLevelID IN 2,3,5,6,7 = Silver/Gold/Platinum/Platinum Plus/Diamond) |

## ETL Pipeline

```
BI_DB_CID_MonthlyPanel_FullData (primary — CID, Equity, TotalDeposits, ClusterDetail)
  +  Dim_Customer (PlayerLevelID filter) + Dim_PlayerLevel (Club name)
  +  BI_DB_AllDeposits (DepositsLast6Months, DepositsLastYear — approved only)
  +  BI_DB_LTV_BI_Actual (LTV = Revenue8Y_LTV_New)
    |-- SP_ClubUsersDataRemarketingGoogle (@date) TRUNCATE+INSERT ---|
    v
BI_DB_dbo.BI_DB_ClubUsersDataRemarketingGoogle (767K rows)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | CID | BI_DB_CID_MonthlyPanel_FullData | CID | Passthrough (BOMonth slice) | Tier 1 — Customer.CustomerStatic |
| 2 | Club | Dim_PlayerLevel | Name | JOIN on Dim_Customer.PlayerLevelID IN (2,3,5,6,7) | Tier 2 — SP_ClubUsersDataRemarketingGoogle |
| 3 | Equity | BI_DB_CID_MonthlyPanel_FullData | EOM_Equity | Rename | Tier 2 — DWH_dbo.V_Liabilities |
| 4 | TotalDeposits | BI_DB_CID_MonthlyPanel_FullData | ACC_TotalDeposits | Rename | Tier 2 — SP_CID_MonthlyPanel_FullData |
| 5 | ClusterDetail | BI_DB_CID_MonthlyPanel_FullData | ClusterDetail | Passthrough | Tier 2 — BI_DB_CID_DailyCluster |
| 6 | DepositsLast6Months | BI_DB_AllDeposits | [Amount in $] | SUM WHERE PaymentStatus='Approved' AND date >= DATEADD(MONTH,-6,@date) | Tier 2 — SP_ClubUsersDataRemarketingGoogle |
| 7 | DepositsLastYear | BI_DB_AllDeposits | [Amount in $] | SUM WHERE PaymentStatus='Approved' AND date >= DATEADD(YEAR,-1,@date) | Tier 2 — SP_ClubUsersDataRemarketingGoogle |
| 8 | LTV | BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New | Passthrough | Tier 2 — BI_DB_LTV_BI_Actual wiki |
| 9 | UpdateDate | ETL | GETDATE() | Runtime timestamp | Propagation |
