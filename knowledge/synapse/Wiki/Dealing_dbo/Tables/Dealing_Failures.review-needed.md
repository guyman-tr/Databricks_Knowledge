# Dealing_dbo.Dealing_Failures — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns.

## Columns Needing Clarification

| Column | Question | Evidence |
|--------|----------|----------|
| ErrorCode | Are error codes stable across the 3 fail sources, or can the same code mean different things? | SP UNIONs all three sources with same ErrorCode column. No deduplication beyond UNION. |

## Structural Questions

| Question | Context |
|----------|---------|
| Is Dealing_Failures_Rate's NULL values (2025-11 onward) an issue? | Recent data shows NULL Failure_Rate. Possibly CopyFromLake.etoro_Hedge_ExecutionLog stopped loading or changed schema. |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
