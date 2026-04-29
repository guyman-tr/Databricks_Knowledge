# Dealing_dbo.Dealing_Apex_PnL_EE_Daily — Review Needed

> Items flagged for domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|
| | | | | | |

## Tier 4 (UNVERIFIED) Columns

- **UpdateDate** — Described as ETL `GETDATE()` at insert; confirm exact semantics if multiple loads per day are possible.

## Columns Needing Clarification

- None beyond **UpdateDate** verification — remaining columns are traced to **`SP_Apex_PnL`** in repo analysis.

## Structural Questions

- **Stale pipeline**: Confirm whether daily Apex equity loads are intentionally discontinued or should be restarted; downstream consumers may still assume freshness.
- **Alignment with `Dealing_Apex_PnL_EE`**: Any business rule changes on the WTD table should be mirrored here — confirm single owner for both.
- **Cross-reference**: Prior review text pointed readers to **`Dealing_Apex_PnL_EE`** review — keep both objects synchronized when SME answers land.
