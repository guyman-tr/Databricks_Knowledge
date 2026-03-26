# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all 21 columns are Tier 2 with verified SP code provenance.

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| IsRedeem | Hardcoded to 0 — is there a plan to populate this from eMoney redemption data? |
| IsIBANQuickTransfer | Hardcoded to 0 — confirm whether MoveMoneyReasonID=6 filtering should be wired here or only in AllPlatforms |
| IsRecurring | Hardcoded to 0 — confirm whether eMoney has a recurring deposit feature or this is TP-only |
| TxTypeID = 8 | SP header says TxTypeID=8 (trade open) "may be removed upon further discussions" — confirm current status |

## Structural Questions

| Topic | Question |
|-------|----------|
| Currency mapping | Changed from Dim_Currency to eMoney_Currency_Instrument_Mapping_Static for deposits (2025-12-23) — confirm this mapping is authoritative and covers all currencies |
| Deduplication | Added 2025-12-31 for symmetry with TP — confirm whether eMoney actually produces duplicate TransactionIDs or this is purely defensive |
| ReferenceNumber 'P' prefix | Confirm the business meaning of the 'P' prefix pattern in ReferenceNumber for IsTradeFromIBAN detection |
