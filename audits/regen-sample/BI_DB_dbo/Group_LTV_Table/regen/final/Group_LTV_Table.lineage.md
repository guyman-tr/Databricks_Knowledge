# Lineage: BI_DB_dbo.Group_LTV_Table

## Source Objects

| # | Source Object | Source Type | Schema | How Used |
|---|--------------|-------------|--------|----------|
| 1 | BI_DB_LTV_BI_Actual | Table | BI_DB_dbo | Revenue8Y_LTV_New, Revenue8Y_LTV_NoExtreme_New, CID, FirstDepositDate — base population and LTV values |
| 2 | Dim_Customer | Table | DWH_dbo | GCID, CountryID, VerificationLevelID — customer identity and compliance attributes |
| 3 | Dim_Country | Table | DWH_dbo | MarketingRegionManualName (→ Region) — marketing region classification |
| 4 | BI_DB_CIDFirstDates | Table | BI_DB_dbo | GCID join — customer lifecycle lookup (LEFT JOIN, used for population context) |
| 5 | BI_DB_CID_MonthlyPanel_FullData | Table | BI_DB_dbo | EOM_Equity, ClusterDetail, FirstAction at Seniority=1 — first-month behavioral and equity attributes |
| 6 | SP_Group_LTV_Table | Stored Procedure | BI_DB_dbo | Writer SP — computes group-level LTV averages by (equity tier × cluster × region) |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| First_Month_Equity_Tier | BI_DB_CID_MonthlyPanel_FullData / Dim_Country | EOM_Equity, ClusterDetail, MarketingRegionManualName | CASE expression: region-specific equity tier bucketing at Seniority=1. Tier 1 (<$100 or NULL), Tier 2 ($100–$500 with region×cluster overrides), Tier 3 (≥$500) | Tier 2 |
| First_Month_Cluster | BI_DB_CID_MonthlyPanel_FullData / Dim_Customer | ClusterDetail, FirstAction, VerificationLevelID | CASE: ClusterDetail if not null; else 'No Cluster - Active' (if FirstAction not null and V3); else 'No Cluster - Inactive' | Tier 2 |
| Region | Dim_Country | MarketingRegionManualName | Rename passthrough (MarketingRegionManualName → NewMarketingRegion → Region) via GROUP BY | Tier 1 |
| Revenue8Y_LTV_New_Group_LTV | BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New | AVG() across cohort group (equity tier × cluster × region) | Tier 2 |
| Revenue8Y_LTV_NoExtreme_New_Group_LTV | BI_DB_LTV_BI_Actual | Revenue8Y_LTV_NoExtreme_New | AVG() across cohort group (equity tier × cluster × region) | Tier 2 |
| Clients | SP_Group_LTV_Table | — | COUNT(*) per group | Tier 2 |
| UpdateDate | SP_Group_LTV_Table | — | GETDATE() at SP execution time | P |
