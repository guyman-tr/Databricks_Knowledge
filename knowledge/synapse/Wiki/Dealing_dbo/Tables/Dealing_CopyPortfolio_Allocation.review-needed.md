# Dealing_dbo.Dealing_CopyPortfolio_Allocation — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Columns Needing Clarification

| Column / Topic | Question | Evidence |
|----------------|----------|----------|
| NOP currency | Is NOP in a consistent currency (USD) or native instrument currency? The SP uses `SUM(NOP)` from BI_DB_PositionPnL without explicit FX conversion. | SP code line 32: `SUM(bdppl.NOP) AS NOP` |
| CopyType=Portfolio vs CopyTrader | Is there a separate table for CopyTrader allocations, or does only CopyPortfolio get this allocation breakdown? | SP filters to `CopyType='Portfolio'` only |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
