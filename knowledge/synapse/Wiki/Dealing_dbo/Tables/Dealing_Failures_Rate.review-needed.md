# Dealing_dbo.Dealing_Failures_Rate — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns.

## Columns Needing Clarification

| Column | Question | Evidence |
|--------|----------|----------|
| Failure_Rate | Why are recent values (Nov 2025+) NULL? | Query shows NULL Failure_Rate for 2025-11-05 through 2025-11-07. Last non-NULL value 2025-04-21 = 0.013392. Source data may have stopped loading. |

## Structural Questions

| Question | Context |
|----------|---------|
| Is this table still actively consumed? | With NULL values for recent months, dashboards relying on this metric would show blanks. |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
