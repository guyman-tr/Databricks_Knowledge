# BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep — Review Needed

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
| Total_Approved_Deposit | Described as "total approved deposit amount (USD)" | Fact_BillingDeposit.Amount currency is assumed USD. Could be in local currency or original deposit currency. Needs AML team confirmation. |
| Group_Type for 2-4 CIDs | Described as "no Group_Type label covers 2-4 CID groups" (possible NULL) | The CASE expression in the SP maps 5-20/21-50/51-500/500+ but HAVING COUNT >= 2 allows 2-4. Unclear if 2-4 CID groups produce NULL Group_Type or are filtered elsewhere. |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| FundingID NOT IN (1-7) | What are FundingIDs 1-7? Are these hardcoded internal/test IDs or dynamic? If the Billing team adds a new internal FundingID (e.g., #8), would it incorrectly appear in AML results? |
| SP_AML_Multiple_Accounts schedule | This SP is not in the OpsDB SB_Daily schedule. Is it run on-demand by the AML team, or is there a separate scheduler (e.g., Azure Data Factory, manual trigger)? |
| IsBlocked source | IsBlocked comes from External_etoro_Billing_Funding. Is this external table refreshed daily? If the SP is run on-demand and the external table is stale, IsBlocked may not reflect the current Billing state. |

## Structural Questions

- Total_Approved_Deposit is type int. Can the sum of all deposits for a high-volume FundingID overflow int (max ~2.1B)? For FundingIDs used by 500+ customers, this seems plausible.
- The table has no unique index on FundingID. Is FundingID guaranteed to be unique per row, or can a FundingID appear multiple times?
- Why is this ROUND_ROBIN rather than HASH(FundingID)? JOINs to _Dep_fulldata on FundingID would benefit from hash distribution.

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
