# DWH_dbo.Dim_ContractType - Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None - all columns have Tier 2-3 evidence.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| Name abbreviations | Full meanings inferred: CPR=Cost Per Registration, CPA=Cost Per Acquisition, Rev=Revenue Share, Hyb=Hybrid, eCost=electronic cost, ZeroCost=no commission, CPL=Cost Per Lead. Are these correct? Are there formal definitions in affiliate agreements? |
| InsertDate/UpdateDate | All NULL in live DWH. Were these always NULL in the legacy DWH SQL Server source, or were they populated and lost during migration? |

## Structural Questions

| Question | Context |
|----------|---------|-
| ETL mechanism | No writer SP found. How are new commission models added if the affiliate program introduces new deal types? Manual DBA insert only? |
| SP_Dim_Affiliate alignment | SP_Dim_Affiliate derives ContractType via CASE on ContractName text (LIKE '%cpr%' etc.), producing values 0-8. This parallels Dim_ContractType IDs but is independent. Should there be a lookup JOIN to enforce consistency? |
| Type mismatch | Dim_Affiliate.ContractType is tinyint; Dim_ContractType.ContractTypeID is int. Is this intentional? JOINs may require implicit CAST. |
| Missing rows 9+ | Current table has 9 rows (IDs 0-8). SP_Dim_Affiliate CASE only produces values 0 and 7 (two branches found in code). Are IDs 1-6, 8 actually populated in Dim_Affiliate.ContractType? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
