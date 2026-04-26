# Review Needed — BI_DB_dbo.BI_DB_M_AML_Report

Generated: 2026-04-22 | Batch: 29

## Tier 4 / Unresolved Items

| Column | Issue | Action Needed |
|--------|-------|---------------|
| Is_Active | SP comment says "Any Trading activity, Deposit, Cash Out for the past 3 months" but code uses `DATEADD(MONTH, -12, @Date)` — actual window is 12 months. | Reviewer: confirm intended Is_Active window (3 months or 12 months); SP comment may be stale. |
| Is_EEA_EU_Country | Based on hardcoded list of 37 DWHCountryIDs in SP. Not driven by Dim_Country or any flag column. | Reviewer: confirm hardcoded EU/EEA list is current; Brexit handling is implicit (UK not in list). |
| AML_Sub_Entity | LEFT JOIN to BI_DB_AML_SubEntity_Categorization (daily rebuild). Sub-entity in historical EOM rows reflects current daily state, not historical EOM state. | Reviewer: confirm whether AML_Sub_Entity is expected to be historically stable or always reflects current classification. |

## Known Data Quality Issues

1. **Wire Threshold Hardcoded ($150K)**: The large wire threshold (`AmountUSD >= 150000`) and funding type (`FundingTypeID=2`) are hardcoded in the SP. No dimension or config table governs this value.

2. **RiskGroup = Country Risk (Not Customer Risk)**: Despite the column name `RiskGroup`, this maps to `Dim_Country.RiskGroupID` — it reflects country-level risk classification, not individual customer AML risk. The customer-level AML score is `RiskScore` (from external classification feed).

3. **RiskScore NULL (~0.1%)**: Approximately 124,588 rows (across all months) have NULL RiskScore — customers not yet classified by the external risk system. These are distinct from "Low" risk customers.

4. **ScreeningStatus NULL (~0.4%)**: Approximately 621,843 rows have NULL or empty ScreeningStatus — customers where Dim_Customer.ScreeningStatusID does not join to Dim_ScreeningStatus or is NULL.

5. **External_RiskClassification Source Not in Standard DWH**: `External_RiskClassification_dbo_V_RiskClassificationDataLake` is not a DWH_dbo dimension — it is an external feed table in BI_DB_dbo. Its refresh schedule, coverage, and data quality are not governed by the standard DWH ETL pipeline.

## Open Questions

- What is the official Is_Active lookback window for AML reporting purposes — 3 months or 12 months?
- Is the EU/EEA country list (37 DWHCountryIDs) maintained as part of SP change management? How are new EU members added?
- Is `External_RiskClassification_dbo_V_RiskClassificationDataLake` documented elsewhere? Its lineage and refresh are unknown to this wiki.
- The SP does not have a DDL creation comment or author field. Who owns `SP_M_AML_Report`?

## Upstream Wiki Coverage

| Source | Wiki Exists? | Tier 1 Columns Inherited |
|--------|-------------|--------------------------|
| Customer.CustomerStatic | Yes (via Dim_Customer.md) | CID |
| Dictionary.Country | Yes (via Dim_Country.md) | Country, RiskGroup |
| BackOffice.Customer | Yes (via Dim_Customer.md) | HasWallet, VerificationLevelID |
| BI_DB_AML_SubEntity_Categorization | Yes (Batch 15) | AML_Sub_Entity (Tier 2 relay) |
