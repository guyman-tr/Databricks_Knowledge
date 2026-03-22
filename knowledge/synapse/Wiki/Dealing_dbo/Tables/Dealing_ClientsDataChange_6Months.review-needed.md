---
object: Dealing_ClientsDataChange_6Months
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_ClientsDataChange_6Months — Review Notes

## Auto-Generated Flags

- **Avg3Month column names in 6-month table**: Both `Avg3MonthInvestedAmt` and `Avg3MonthOrderSize` carry "3Month" prefix in the 6-month table. This appears to be copied from the 3Months table schema without renaming. Reviewer: confirm these are the same current-week averages and the naming is a known inconsistency.
- **Date as datetime**: Same as 3Months — datetime type instead of date. May affect join behavior.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
