# BI_DB_dbo.BI_DB_AML_Email_for_KYT — Review Needed

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
| _of_transfer | Assumed to be "fraction of transfer attributable to high-risk exposure (0.0–1.0)" | Column name has leading underscore (ETL artifact) and is a float. Could be a percentage (0-100) rather than fraction (0-1). Cannot verify from empty table. |
| tx_index | Assumed to be "transaction index within the block" | Could also be output index within the transaction (UTXO model). Cannot verify from empty table. |
| state | Described as "alert processing state" | Different KYT providers use different state values. Exact value set unknown. Cannot verify from empty table. |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| DECOMMISSION STATUS | Is BI_DB_AML_Email_for_KYT permanently decommissioned, or is there a plan to re-activate it with a different KYT provider? The JUNK_ prefix and 0 rows suggest permanent decommission, but AML teams sometimes pause pipelines during provider transitions. |
| Current KYT pipeline | If this table is decommissioned, what is the current source for KYT alerts in the AML workflow? Is there a replacement table or a direct integration into the Alert Service? |
| user_id resolution | The SP joins EXW_AMLProviderID ON ProviderUserIDNormalized = kk.user_id COLLATE Latin1_General_100_BIN. Was the collation match always reliable? Were there identity resolution failures (NULL CIDs) that contributed to the decommission decision? |

## Structural Questions

- Why is the table still present in the SSDT schema if it is decommissioned? Should the DDL and SP be removed or archived to avoid confusion?
- The JUNK_ prefix convention — is this the standard eToro Data Platform signal for a decommissioned SP, or is it informal? Is there a formal deprecation process?

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
