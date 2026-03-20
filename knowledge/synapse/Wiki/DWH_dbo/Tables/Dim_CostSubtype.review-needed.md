# DWH_dbo.Dim_CostSubtype - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns in this document.

## Columns Needing Clarification

| Column / Topic | Question |
|----------------|----------|
| CostSubtypeId (Relationship) | Is Dim_CostSubtype.CostSubtypeId referenced by Fact_History_Cost? No SP grep match found. Please confirm the downstream consumers. |
| SDRT (ID=3) | Is Stamp Duty Reserve Tax still actively used? Is this EU/global or UK-only? Any specific instruments where SDRT applies? |
| Refund (ID=5) | Do Refund rows reduce the net cost in Fact_History_Cost (negative amounts), or are they separate positive reversal rows? |
| FixPerLotFee (ID=6) | Which instrument types use per-lot fees? Futures, CFDs, or specific asset classes? |

## Structural Questions

| Question |
|----------|
| Why ROUND_ROBIN for a 7-row table? Should this be REPLICATE for broadcast joins? |
| HistoryCosts is not in the Generic Pipeline. What is the actual mechanism that loads DWH_staging.HistoryCosts_Dictionary_CostSubtype - ADF pipeline, SQL linked server, or something else? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
