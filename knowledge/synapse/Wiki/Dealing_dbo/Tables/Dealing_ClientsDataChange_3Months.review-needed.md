---
object: Dealing_ClientsDataChange_3Months
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_ClientsDataChange_3Months — Review Notes

## Auto-Generated Flags

- **Naming caveat**: `Avg3MonthInvestedAmt` and `Avg3MonthOrderSize` are documented as current-week metrics with "3Month" prefix indicating the comparison table. Reviewer: confirm these columns are NOT rolling 3-month averages.
- **Date column is datetime**: Unlike ClientDataFinal (date), this table uses datetime for the Date column. Is this intentional? May cause join issues if comparing to other tables.
- **"Change" data**: This table stores absolute current values, not delta (change) values. The change is implicit (current week vs. 3-months-ago week in a separate calculation). Confirm this is the expected schema.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
