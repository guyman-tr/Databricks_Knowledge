---
object: Dealing_dbo.Dealing_DailyVariableSpread
review_status: pending
documented: 2026-03-21
---

# Review Needed: Dealing_DailyVariableSpread

## Auto-Generated Flags

- [ ] **LabelID 26 and 30**: Confirm what these labels represent — are they test accounts, demo accounts, or specific client segments? Document for future users.
- [ ] **`Commissions` vs `FullCommissions` difference**: Clarify what additional components `FullCommissions` includes beyond `Commissions`. Is the difference a regulatory fee, a specific product fee, or something else?
- [ ] **`FullDate` naming**: Unusual primary date column name (vs standard `Date`). Confirm if intentional to distinguish from a `Date` column in the source.
- [ ] **Negative `RollOverFee`**: Confirm if negative rollover values occur and what they represent (client credit on short positions with dividends?).

## Reviewer Corrections

<!-- Add corrections here. -->
