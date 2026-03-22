# Dealing_dbo.Dealing_CEP_ExecutionMonitoring — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns.

## Columns Needing Clarification

| Column | Question | Evidence |
|--------|----------|----------|
| TranType='LabelID=30' | What does LabelID=30 represent? Internal/test accounts? | SP uses `c.LabelID` from Dim_Customer. LabelID=30 is separated into its own TranType category. |
| Success | Was the filter change (removing Success=1) intentional? | Change log 2020-02-04 says "Removing Filter Success = 1". Now includes both successful and failed LP executions. |

## Structural Questions

| Question | Context |
|----------|---------|
| How is this table consumed? | Used for CEP rule validation. Is there a dashboard or automated alert on LP vs Client volume discrepancies? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
