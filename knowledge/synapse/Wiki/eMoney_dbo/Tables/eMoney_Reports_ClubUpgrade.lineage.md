# Lineage: eMoney_dbo.eMoney_Reports_ClubUpgrade

**Generated**: 2026-04-21 | **Writer SP**: SP_eMoney_Reports_Daily (Steps 8-11)

## ETL Chain

```
DWH_dbo.Dim_Customer (etoro.Customer.CustomerStatic origin)
DWH_dbo.Fact_SnapshotCustomer (historical daily snapshots)
DWH_dbo.Dim_PlayerLevel (etoro.Dictionary.PlayerLevel origin)
DWH_dbo.Dim_Date
DWH_dbo.Dim_Range
eMoney_dbo.eMoney_Dim_Account
eMoney_dbo.eMoney_Dim_Country_Rollout
  |-- SP_eMoney_Reports_Daily (Steps 8-11: #pop → #club_upgrade → #final → TRUNCATE/INSERT) ---|
  v
eMoney_dbo.eMoney_Reports_ClubUpgrade
  |-- Generic Pipeline (Gold export) ---|
  v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|----------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Rename passthrough: `dc.RealCID AS 'CID'` | Tier 1 |
| 2 | GCID | DWH_dbo.Dim_Customer | GCID | Direct passthrough | Tier 1 |
| 3 | Club | DWH_dbo.Dim_PlayerLevel | Name | Current club name; JOIN on current PlayerLevelID from Fact_SnapshotCustomer | Tier 2 |
| 4 | Previous_Club | DWH_dbo.Dim_PlayerLevel | Name | Previous club name; LAG(PlayerLevelID) → join Dim_PlayerLevel.Name | Tier 2 |
| 5 | Club_ID | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | Current tier ID from snapshot history | Tier 2 |
| 6 | Previous_ClubID | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID (LAG) | ETL-computed: `LAG(PlayerLevelID,1,0) OVER(PARTITION BY RealCID ORDER BY FromDateID)` | Tier 2 |
| 7 | Club_Upgrade_Date | DWH_dbo.Dim_Date | FullDate | Date of club change event from Dim_Date.DateKey | Tier 2 |
| 8 | Is_eTM | eMoney_dbo.eMoney_Dim_Account | GCID | `CASE WHEN mda.GCID IS NOT NULL THEN 1 ELSE 0` (IsValidETM=1, GCID_Unique_Count=1 filter) | Tier 2 |
| 9 | UK/EU | DWH_dbo.Dim_Customer | CountryID | `CASE WHEN CountryID = 218 THEN 'UK' ELSE 'EU'` (218 = United Kingdom) | Tier 2 |
| 10 | Country | eMoney_dbo.eMoney_Dim_Country_Rollout | CountryName | Direct passthrough (eToro Money rollout countries only) | Tier 2 |
| 11 | AccountProgram | eMoney_dbo.eMoney_Dim_Account | AccountProgram | Passthrough via LEFT JOIN (IsValidETM=1, GCID_Unique_Count=1). NULL if no eTM account. | Tier 2 |
| 12 | AccountSubProgram | eMoney_dbo.eMoney_Dim_Account | AccountSubProgram | Passthrough via same LEFT JOIN filter. NULL if no eTM account. | Tier 2 |
| 13 | UpdateDate | ETL | N/A | `GETDATE()` at SP execution time | Tier 2 |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | CID, GCID |
| Tier 2 | 11 | Club, Previous_Club, Club_ID, Previous_ClubID, Club_Upgrade_Date, Is_eTM, UK/EU, Country, AccountProgram, AccountSubProgram, UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
