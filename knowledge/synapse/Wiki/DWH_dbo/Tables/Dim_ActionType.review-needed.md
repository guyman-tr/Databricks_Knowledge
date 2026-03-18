# DWH_dbo.Dim_ActionType — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — all elements described from live data (Tier 3) or migration DDL (Tier 2b).

## Columns Needing Clarification

- **Category/CategoryID relationship**: Category and CategoryID appear self-contained in this table. Is there a separate category reference table anywhere, or are these always managed inline?
- **ActionTypeID gaps**: IDs skip 33. Was ActionTypeID=33 removed, or was it never assigned?

## Structural Questions

- **Active ETL**: This table has no active ETL (no SP writes to it). New action types (e.g., InternalDeposit=44, InternalWithdraw=45 from April 2024) appear to be inserted manually. Is this the intended long-term approach, or should this table be added to SP_Dictionaries?
- **Source table identity**: The legacy DWH SQL Server source is unclear. Was this table originally DWH.dbo.Dim_ActionType on the old on-premises DWH, or was it derived from a production Dictionary table that has since been restructured?
- **Production Dictionary.ActionType mismatch**: Production etoro.Dictionary.ActionType (16 rows, game/registration events) is completely different from this DWH table (45 rows, trading/financial events). Is this a known divergence? Was the production table repurposed at some point?

## Tier 5 Re-Review Needed

_No Tier 5 overrides exist for this object._
