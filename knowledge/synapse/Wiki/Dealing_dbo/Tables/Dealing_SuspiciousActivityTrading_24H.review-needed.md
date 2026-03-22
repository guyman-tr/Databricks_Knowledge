---
object: Dealing_SuspiciousActivityTrading_24H
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_SuspiciousActivityTrading_24H — Review Notes

## Auto-Generated Flags

- **NULL sentinel rows**: On days with no suspicious activity, one NULL row exists for that date. Confirm all consumers handle this correctly (filter `WHERE CID IS NOT NULL` for actual alerts).
- **Date is datetime (not date)**: Time portion always 00:00:00. May cause issues in date comparisons — use CAST to date.
- **Thresholds hardcoded**: 3-minute window, ≥5 trades, >$3,000 profit, >$10,000 tree profit for copies. Are these thresholds reviewed periodically? Last adjustment: Nov 2021 (per SP header).
- **IsPI = "Important PI"**: Only flags PIs with >10 active copiers. A PI with 9 copiers is IsPI=0 even if their trading affects thousands through cascading copies. Confirm the threshold is still appropriate.
- **"IsPI" column name**: The column is actually "Is_RootCID_ImportantPI" in the SP logic but stored as `IsPI` — same as other tables where IsPI means "is a Popular Investor." Here it means "has >10 active copiers," which is a stricter definition.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
