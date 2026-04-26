# BI_DB_dbo.BI_DB_MifidAccountType_Count — Column Lineage

Generated: 2026-04-22 | Batch: 29 | Writer SP: SP_MifidAccountType_Count

## ETL Pipeline Summary

| Property | Value |
|----------|-------|
| **Writer SP** | `BI_DB_dbo.SP_MifidAccountType_Count` |
| **Author** | Unknown (no DDL comment) |
| **Load Pattern** | DELETE WHERE Date = DATEADD(DAY,-30,GETDATE()) + INSERT (rolling 30-day window design) |
| **Frequency** | Daily (SB_Daily, Priority 20) — runs on GETDATE(), no date parameter |
| **Row Count** | ~7,962,423 (2029 distinct run dates, 2020-09-22 to 2026-04-13; ~3,900 rows/run) |
| **UC Target** | Not Migrated |

## Column Lineage

| Column | Source Table | Source Column | Transform | Tier |
|--------|-------------|---------------|-----------|------|
| AccountType | Dim_AccountType | Name | lookup via Dim_Customer.AccountTypeID | Tier 1 — Dictionary.AccountType |
| Country | Dim_Country | Name | lookup via Dim_Customer.CountryID (alias dc1) | Tier 1 — Dictionary.Country |
| Region | Dim_Country | Region | passthrough from Dim_Country (marketing region label) | Tier 2 — SP_Dictionaries_Country_DL_To_Synapse |
| Desk | Dim_Country | Desk | passthrough from Dim_Country (sales/support desk) | Tier 3 — Ext_Dim_Country_Region_Desk via SP |
| Regulation | Dim_Regulation | Name | lookup via Dim_Customer.RegulationID (alias dr) | Tier 2 — SP_MifidAccountType_Count |
| Count | Dim_Customer | RealCID | COUNT(RealCID) GROUP BY all dimension columns | Tier 2 — SP_MifidAccountType_Count |
| Date | — | GETDATE() | GETDATE() cast to date — run timestamp | Tier 5 — ETL metadata |
| UpdateDate | — | — | GETDATE() | Tier 5 — ETL metadata |
| MifidCategorization | Dim_MifidCategorization | Name | lookup via Dim_Customer.MifidCategorizationID | Tier 1 — Dictionary.MifidCategorization |

## Source Objects

| Object | Schema | Purpose |
|--------|--------|---------|
| Dim_Customer | DWH_dbo | Base population (IsValidCustomer=1); provides MifidCategorizationID, AccountTypeID, CountryID, RegulationID, RealCID for COUNT |
| Dim_MifidCategorization | DWH_dbo | MifidCategorization text lookup (6 rows) |
| Dim_AccountType | DWH_dbo | AccountType text lookup |
| Dim_Country | DWH_dbo | Country name, Region, and Desk (via MarketingRegionID → Ext_Dim_Country_Region_Desk) |
| Dim_Regulation | DWH_dbo | Regulation name text lookup |

## UC External Lineage

Not applicable — UC Target: Not Migrated.
