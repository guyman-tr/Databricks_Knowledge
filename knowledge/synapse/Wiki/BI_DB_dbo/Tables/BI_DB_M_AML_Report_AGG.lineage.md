# BI_DB_dbo.BI_DB_M_AML_Report_AGG — Column Lineage

Generated: 2026-04-22 | Batch: 29 | Writer SP: SP_M_AML_Report

## ETL Pipeline Summary

| Property | Value |
|----------|-------|
| **Writer SP** | `BI_DB_dbo.SP_M_AML_Report` |
| **Author** | Unknown (no DDL comment) |
| **Load Pattern** | DELETE WHERE EOM + INSERT (monthly partition upsert; same SP run as BI_DB_M_AML_Report) |
| **Intermediate** | `#agg_table` temp table (GROUP BY of `#Final_Table`) |
| **Frequency** | Monthly (per EOM parameter) |
| **Row Count** | ~1,234,686 (~42K–44K groups per EOM; 28 months 2023-12 to 2026-03) |
| **UC Target** | Not Migrated |

## Column Lineage

| Column | Source Table | Source Column | Transform | Tier |
|--------|-------------|---------------|-----------|------|
| CID | #Final_Table (from Fact_SnapshotCustomer.RealCID) | CID | COUNT(CID) GROUP BY all dimensions — **customer COUNT, not customer ID** | Tier 2 — SP_M_AML_Report aggregation |
| Regulation | Dim_Regulation | Name | GROUP BY key; passthrough from #Final_Table | Tier 2 — SP_M_AML_Report |
| Country | Dim_Country | Name | GROUP BY key; passthrough from #Final_Table | Tier 1 — Dictionary.Country |
| PlayerStatus | Dim_PlayerStatus | Name | GROUP BY key; passthrough from #Final_Table | Tier 2 — SP_M_AML_Report |
| PlayerStatusReason | Dim_PlayerStatusReasons | Name | GROUP BY key; passthrough from #Final_Table | Tier 2 — SP_M_AML_Report |
| Club | Dim_PlayerLevel | Name | GROUP BY key; passthrough from #Final_Table | Tier 2 — SP_M_AML_Report |
| RiskGroup | Dim_Country | RiskGroupID | GROUP BY key; passthrough; renamed from RiskGroupID | Tier 1 — Dictionary.Country |
| RiskScore | External_RiskClassification_dbo_V_RiskClassificationDataLake | RiskScoreName | GROUP BY key; passthrough from #Final_Table | Tier 2 — SP_M_AML_Report |
| Is_FTD | Dim_Customer | FirstDepositDate | GROUP BY key; CASE computed in #Final_Table | Tier 2 — SP_M_AML_Report |
| Is_Active | Fact_CustomerAction | RealCID | GROUP BY key; CASE EXISTS in #Final_Table | Tier 2 — SP_M_AML_Report |
| ScreeningStatus | Dim_ScreeningStatus | Name | GROUP BY key; passthrough from #Final_Table | Tier 2 — SP_M_AML_Report |
| HasWallet | Dim_Customer | HasWallet | GROUP BY key; passthrough | Tier 1 — BackOffice.Customer |
| Wire_Transactions | Fact_BillingDeposit | DepositID | SUM(Wire_Transactions) GROUP BY — summed across group | Tier 2 — SP_M_AML_Report |
| Wire_Amount | Fact_BillingDeposit | AmountUSD | SUM(Wire_Amount) GROUP BY — summed across group | Tier 2 — SP_M_AML_Report |
| Prev_Regulation | Fact_RegulationTransfer + Dim_Regulation | FromRegulationID → Name | GROUP BY key; passthrough from #Final_Table | Tier 2 — SP_M_AML_Report |
| EOM | — | @Date param | GROUP BY key; EOMONTH(@Date) | Tier 5 — ETL metadata |
| UpdateDate | — | — | GETDATE() | Tier 5 — ETL metadata |
| VerificationLevelID | Dim_Customer | VerificationLevelID | GROUP BY key; passthrough | Tier 1 — BackOffice.Customer |
| Is_EEA_EU_Country | Dim_Country | DWHCountryID | GROUP BY key; CASE in hardcoded list | Tier 2 — SP_M_AML_Report |
| AML_Sub_Entity | BI_DB_AML_SubEntity_Categorization | AML_Sub_Entity | GROUP BY key; passthrough from #Final_Table | Tier 2 — SP_M_AML_Report |

## Source Objects

Identical to BI_DB_M_AML_Report — all source objects are the same (data flows through #Final_Table intermediate). See BI_DB_M_AML_Report.lineage.md for the full source object list.

## UC External Lineage

Not applicable — UC Target: Not Migrated.
