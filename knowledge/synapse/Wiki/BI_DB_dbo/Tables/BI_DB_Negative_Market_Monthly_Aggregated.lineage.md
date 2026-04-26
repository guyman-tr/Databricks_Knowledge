# Lineage: BI_DB_dbo.BI_DB_Negative_Market_Monthly_Aggregated

## Source Chain

| Level | Object | Type | Role |
|-------|--------|------|------|
| L0 | ComplianceStateDB.Compliance.CustomerRestrictions | Production DB | CFD restriction events |
| L0 | ComplianceStateDB.Compliance.UserTradingData | Production DB | Current CFD restriction status |
| L0 | ComplianceStateDB.History.UserTradingData | Production DB | Historical CFD restriction events |
| L1 | BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerRestrictions | External Table | Lake bridge for CustomerRestrictions |
| L1 | BI_DB_dbo.External_ComplianceStateDB_Compliance_UserTradingData | External Table | Lake bridge for UserTradingData |
| L1 | BI_DB_dbo.External_ComplianceStateDB_History_UserTradingData | External Table | Lake bridge for History |
| L2 | DWH_dbo.Dim_Customer | DWH Dimension | RealCID, RegulationID, CountryID enrichment |
| L2 | DWH_dbo.Dim_Regulation | DWH Dimension | Regulation name lookup |
| L2 | DWH_dbo.Dim_Country | DWH Dimension | Country name lookup |
| L3 | BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | BI_DB Table | Parent table — individual-level appropriateness test rows |
| L4 | BI_DB_dbo.BI_DB_Negative_Market_Monthly_Aggregated | **THIS TABLE** | Monthly EOM aggregation |

## ETL Pipeline

```
ComplianceStateDB.Compliance.CustomerRestrictions (production)
ComplianceStateDB.Compliance.UserTradingData (production)
ComplianceStateDB.History.UserTradingData (production)
  |-- Generic Pipeline (Bronze export to lake) ---|
  v
BI_DB_dbo.External_ComplianceStateDB_* (external tables — lake bridge)
  |-- SP_BI_DB_Scored_Appropriateness_Negative_Market @Date ---|
  v
BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market (daily TRUNCATE+INSERT)
  |-- SP_BI_DB_Scored_Appropriateness_Negative_Market (EOM block: IF @Date=EOMONTH(@Date)) ---|
  v
BI_DB_dbo.BI_DB_Negative_Market_Monthly_Aggregated (monthly TRUNCATE+INSERT, single-month retained)
  |-- UC: Not Migrated ---|
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | EOMonth | SP-computed | @Date (EOMONTH) | EOMONTH(@Date) — EOM trigger date | Tier 2 |
| 2 | DspositorInd | BI_DB_Scored_Appropriateness_Negative_Market | FTD_Date | CASE WHEN FTD_Date != '1900-01-01' AND FTD_Date <= @Date THEN '1' ELSE '0' | Tier 2 |
| 3 | RegulationName | DWH_dbo.Dim_Regulation | Name | DspositorInd=1 → RegulationName; DspositorInd=0 → DesignatedRegulationName. Passthrough string. | Tier 1 |
| 4 | CountryName | DWH_dbo.Dim_Country | Name | Passthrough string join | Tier 1 |
| 5 | [Total Customers] | BI_DB_Scored_Appropriateness_Negative_Market | RealCID | COUNT(RealCID) per group | Tier 2 |
| 6 | CFDBlockedUsers | BI_DB_Scored_Appropriateness_Negative_Market | BlockDate, ReleaseDate | SUM(CASE WHEN BlockDate <= @Date AND ISNULL(ReleaseDate,'2300-01-01') > @Date THEN 1 ELSE 0 END) | Tier 2 |
| 7 | UpdateDate | SP-computed | GETDATE() | ETL run timestamp | Tier 2 |

## UC External Lineage

UC Target: Not Migrated
