---
object: Dealing_ClientDataRecurring
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_ClientDataRecurring — Review Notes

## Auto-Generated Flags

- **Lookback window naming**: The column `percentageOf2week` and `percentageOf4week` use lowercase and different naming convention than `PercentageOfReturn`. Confirm: "2week" = 2 weeks ago (14–21 days) and "4week" = 4 weeks ago (28–35 days)?
- **No country breakdown**: Unlike ClientDataFinal, this table has one row per instrument per week (no Country dimension). Is this intentional?
- **Float vs. percentage**: Values are 0–1 ratios. Dashboard consumers need to multiply by 100. Worth confirming this is consistent with how Tableau references these columns.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
