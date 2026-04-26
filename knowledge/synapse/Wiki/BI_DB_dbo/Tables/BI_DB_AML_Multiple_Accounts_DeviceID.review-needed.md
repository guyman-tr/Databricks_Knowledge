# BI_DB_dbo.BI_DB_AML_Multiple_Accounts_DeviceID — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all 3 elements are directly derivable from the SP logic with high confidence.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| ClientDeviceId format | The column is nvarchar(250) and the SP excludes the all-zeros GUID. Are all device IDs GUID format, or can they also be other identifiers (e.g., MAC addresses, browser fingerprints)? |
| STS_User_Operations_Data_History | Is this table the same as STS_Audit_UserOperationsData used in other DWH SPs? Or a different history table? The source table name should be confirmed against the actual SSDT DDL. |
| DateID >= 20230101 cutoff | Why January 2023 specifically? Was this chosen as the start of reliable device ID logging, or is it a business decision by the AML team? |
| NumOfClientsSameDeviceID minimum | The HAVING clause filters COUNT > 1 (minimum 2). Are groups with exactly 2 sharing customers meaningful for AML, or do analysts typically focus on 5+ sharing customers? |

## Structural Questions

- With 758K rows, this is a large HEAP table with no index. Query performance for GROUP BY ClientDeviceId (for counting or joining) relies on full scans. Would an index on ClientDeviceId improve performance?
- Is NumOfClientsSameDeviceID refreshed with the full population each run (TRUNCATE + INSERT), or is it incrementally maintained? If incremental, could older records have stale counts?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
