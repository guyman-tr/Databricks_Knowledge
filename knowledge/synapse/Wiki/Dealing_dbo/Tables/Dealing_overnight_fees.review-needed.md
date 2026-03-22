# Dealing_dbo.Dealing_overnight_fees — Review Needed

> Items flagged for offline domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 columns — but all columns are Tier 3 (DDL/live data only). No SP or upstream wiki evidence.

## Columns Needing Clarification

| Column | Question | Evidence |
|--------|----------|----------|
| future_short_cut | What is the complete list of commodity codes? | Sample only shows CL, NG, LN. |
| ticker | What Bloomberg data source feeds this? | Fivetran connector — but which specific connector/table? |
| days | Is this days to expiry or days to rollover? | Context suggests rollover for overnight fee calculation. |
| close | Is this settlement price or last trade price? | Bloomberg "Close" could be either. |

## Structural Questions

| Question | Context |
|----------|---------|
| Is Fivetran sync still active? | Latest sample data is 2024-03-22. If sync stopped, this table may be stale. |
| What is the exact external source? | Fivetran could be syncing from Bloomberg API, Google Sheets, or a CSV feed. |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
