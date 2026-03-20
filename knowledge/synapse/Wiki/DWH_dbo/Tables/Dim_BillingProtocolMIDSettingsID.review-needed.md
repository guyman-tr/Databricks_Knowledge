# DWH_dbo.Dim_BillingProtocolMIDSettingsID -- Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 (UNVERIFIED) columns. 9 of 11 columns have Tier 1 descriptions from the upstream wiki. Description is Tier 3 (name-inferred). UpdateDate is Tier 2 (ETL).

## Columns Needing Clarification

| Column | Issue |
|--------|-------|
| Description | Upstream wiki marks this as NAME-INFERRED. What information is stored here in practice -- depot description, processor name, internal notes? Is it populated consistently or sparse? |

## Structural Questions

1. **ETL freshness issue**: Live data as of 2026-03-18 shows UpdateDate=2026-03-11 (7 days stale). Is SP_Dictionaries_DL_To_Synapse failing or was the pipeline paused? This affects all DWH tables loaded by this SP.
2. **Value column sensitivity**: The Value column contains MID strings and payment credentials. Should this table be masked or access-restricted in Databricks UC? Confirm the data governance policy for payment routing credentials in DWH.
3. **REPLICATE for 1,851 rows**: This is larger than typical REPLICATE tables (most are under 200 rows). Was this intentional? At this row count REPLICATE still works, but as the table grows toward 10K+ rows, consider switching to HASH or ROUND_ROBIN distribution.
4. **Clustered on DepotID vs production ID**: Production clusters on ID (sequential inserts). DWH clusters on DepotID. Verify this is the intended DWH access pattern for this table.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
