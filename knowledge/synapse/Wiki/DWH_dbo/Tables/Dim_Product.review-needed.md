# DWH_dbo.Dim_Product - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

None - all columns are Tier 3 (live data) or above.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| ProductID | What is the original source of this table? Was it migrated from on-premises DWH SQL Server or from a separate eToro product catalog? |
| Product "Other" | Does "Other" represent unclassified sessions/products or a specific legacy product name? |
| UpdateDate 2020-07-28 | What change was made on 2020-07-28 - were Delta and eToroX products added at that time? |

## Structural Questions

- **No active ETL**: No writer SP found anywhere in SSDT. Is Dim_Product intentionally frozen, or has the ETL been lost? Should it be refreshed from a current production source?
- **No consumers in SSDT**: No DWH stored procedure JOINs to this table. Is it exclusively used by reporting layers (BI_DB, Databricks)? If so, should it be documented as a Gold-export-only table?
- **ProductID gaps**: IDs jump from 99 to 101 and skip several numbers (e.g., no 113-related gaps). Are there retired/deleted product rows?
- **Wallet and eToroX**: Both appear on Android, iOS, and Web/Browsers. Are these current product brands or legacy names?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
