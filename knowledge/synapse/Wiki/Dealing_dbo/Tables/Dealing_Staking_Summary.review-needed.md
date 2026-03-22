---
object: Dealing_Staking_Summary
schema: Dealing_dbo
type: table
batch: 12
review_flags:
  - stakingmonthid_malformed_bug
  - percent_unutilized_duplicate_column
  - single_exchange_rate_for_all_usd
quality_score: 8.5
---

## Review Flags

### FLAG 1 — StakingMonthID MALFORMED BUG (HIGH)
**Severity**: High
**Description**: `StakingMonthID = 2025030` (March 2025) is 7 digits due to historical SP bug. MAX(StakingMonthID) returns 2025030 instead of the actual latest month 202602 (February 2026). Table shows 158 rows total but ordering by StakingMonthID DESC puts March 2025 first.
**Action**: Use StakingYear + StakingMonth for temporal ordering. Add `WHERE LEN(CAST(StakingMonthID AS VARCHAR)) = 6` to exclude the malformed record when needed.

### FLAG 2 — DUPLICATE PercentUnutilized / UnutilizedPercent COLUMNS (LOW)
**Severity**: Low
**Description**: `PercentUnutilized` and `UnutilizedPercent` measure the same thing. The historical column `PercentUnutilized` was retained when `UnutilizedPercent` was added. Both should be equal.
**Action**: Prefer `UnutilizedPercent` in new queries. Consider deprecating `PercentUnutilized` in the Unity Catalog target. Verify both columns are equal before doing so.

### FLAG 3 — SINGLE EXCHANGE RATE FOR ALL USD COLUMNS (MEDIUM)
**Severity**: Medium
**Description**: All USD conversion in this table uses `USD_ConversionRate` = BidSpreaded at `staking_end_date`. This means all USD values are point-in-time at period end, not averaged over the staking month. For volatile crypto assets (ETH, SOL, ADA), the end-date rate may not represent the average rate over the staking period.
**Action**: Acceptable for the intended use case (monthly finance reporting), but note when comparing USD values across months with high crypto price volatility. Do not use these USD values for mark-to-market accounting without considering the timing of the rate.
