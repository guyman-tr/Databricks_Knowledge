# Dealing_dbo.Dealing_DealingDashboard_Clients — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Columns Needing Clarification

| Column / Topic | Question | Evidence |
|----------------|----------|----------|
| Zero calculation | Exact formula for RealizedZero and ChangeInUnrealizedZero? The SP constructs these from complex temp tables (#Realized, #TotalZero) that need deeper inspection. | SP lines 178+ — multi-step aggregation |
| VariableSpread sign | Is VariableSpread always positive (revenue to eToro) or can it be negative? | SP computes it differently based on open/close timing |
| IsFuture column values | Is IsFuture a boolean (0/1) or can it have other values? It's typed as int, not bit. | DDL: `[IsFuture] [int] NULL` |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
