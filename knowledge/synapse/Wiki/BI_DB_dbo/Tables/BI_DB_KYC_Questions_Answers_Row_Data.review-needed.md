# Review Needed — BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data

**Generated**: 2026-04-23 | **Batch**: 70 | **Quality**: 8.1/10

## Tier 4 Items (Undetermined — Pending Review)

None. All columns resolved to Tier 1 or Tier 2.

## Questions for Domain Expert

1. **ETL writer unknown**: No Synapse stored procedure writes to this table (confirmed via sys.sql_modules scan). The ETL source appears to be an external pipeline (ADF or SQL Agent job) reading from UserApiDB. Please confirm: (a) what pipeline populates this table, (b) its refresh schedule (full reload vs. incremental append), and (c) whether it is registered in OpsDB.

2. **Not in OpsDB**: `BI_DB_KYC_Questions_Answers_Row_Data` has no entry in the OpsDB orchestration metadata. Is this intentional (external pipeline bypasses OpsDB), or an oversight?

3. **Downstream consumers**: No Synapse SP was found reading from this table (sys.sql_modules scan). Are consumers external (Databricks, reporting tools, ADF)? `BI_DB_KYCUserRawDataLeveled` and `BI_DB_KYC_Score_CID_Level` appear related — please confirm if they join to this table or if they use a different KYC source.

4. **OccurredAt semantics**: Is OccurredAt the time the customer submitted their answers in the eToro app/web, or the time the answer was recorded in the UserApiDB database? Is there a meaningful lag between customer action and OccurredAt?

5. **GCID NULLs**: This table uses GCID, not CID. Are there rows with NULL GCID (pre-GCID-era accounts)? If so, how should analysts handle them — are they safe to exclude, or do they represent a meaningful segment?

## Propagation Metadata

- `UpdateDate` is ETL metadata (pipeline write timestamp) — confirmed Propagation tier.

## Corrections Log

*(Empty — no reviewer corrections yet)*
