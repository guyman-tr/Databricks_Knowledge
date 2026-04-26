# BI_DB_dbo.BI_DB_AML_Periodic_Review_MOP — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Unverified Assumption | Why Uncertain |
|--------|----------------------|---------------|
| MOP | The FundingTypeID exclusion list (1,2,3,4,11,13,15,17,29,30,32,33,34,35,36,37,38) is described as "common/safe methods" | Cannot verify without reading the full Dim_FundingType registry. The excluded IDs may reflect a business decision by the AML team rather than an objective "safe" classification. The exact AML risk categorization logic for MOPs should be confirmed. |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| Writer SP | No SSDT SP or OpsDB entry found for this table. Who maintains the ETL that populates it? Is it a Python script, an SSIS package, a standalone SQL job, or a different SP not yet in SSDT? Identifying the writer is critical for data freshness monitoring. |
| FundingTypeID exclusion list intent | The NOT IN list excludes FundingTypeIDs 1,2,3,4,11,13,15,17,29,30,32,33,34,35,36,37,38. What are these specific IDs? Are all of them truly "safe" from an AML perspective, or were some excluded for technical reasons (e.g., lack of data)? |
| OnlineBanking (67% of rows) | OnlineBanking is the top MOP in this table. Is "OnlineBanking" a single Dim_FundingType entry, or does it aggregate multiple similar methods? Why is it classified as high-risk when it is so prevalent? |
| One row per (CID, MOP) vs. one row per CID | The table has one row per distinct (CID, MOP) pair. In the AML review flow, is the Is_High_MOP_Deposit flag triggered if ANY MOP for this CID is in the table (i.e., EXISTS check), or does the specific MOP matter? |
| Date range | The #mop logic uses DateID >= 20230101. Does this table also use the same 2023 cutoff, or could it use a different date window? |

## Structural Questions

- No primary key or index. For the EXISTS-style lookup used by SP_AML_Periodic_Review, an index on CID would significantly improve performance given 151K rows.
- The writer process is unknown. Should this be tracked in OpsDB, or is there an intentional decision to keep it ad-hoc?
- If SP_AML_Periodic_Review already materializes the #mop temp table internally, why does this separate persistent table exist? Is it for AML analyst ad-hoc queries, or is there a downstream process that depends on it?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
