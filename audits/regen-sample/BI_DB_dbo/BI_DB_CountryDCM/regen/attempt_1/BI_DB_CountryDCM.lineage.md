# BI_DB_dbo.BI_DB_CountryDCM — Column Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Evidence |
|---|---|---|---|---|
| 1 | (Manual load) | Reference data | Static lookup | All 231 rows share UpdateDate 2021-10-13; no writer SP found in SSDT |
| 2 | BI_DB_dbo.SP_DCM_Dashboard | Stored Procedure | Reader | JOINs on Country_DCM to map DCM country names to Affwiz names (line 196) |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | Country_DCM | (Manual load) | — | Static reference value — country name as used in DCM (Double Click Manager) campaigns | Tier 3 |
| 2 | Country_Affwiz | (Manual load) | — | Static reference value — country name as used in Affwiz / internal affiliate systems | Tier 3 |
| 3 | MarketingRegionManualName | (Manual load) | — | Static reference value — manually assigned marketing region grouping | Tier 3 |
| 4 | UpdateDate | (Manual load) | — | Timestamp of when the mapping row was loaded/updated | Tier 3 |
