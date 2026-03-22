---
object: Dealing_Staking_Position
schema: Dealing_dbo
type: table
batch: 12
review_flags:
  - stakingmonthid_malformed_bug
  - eth_opt_in_default_difference
  - non_us_filter_scope_change
  - pi_exclusion_implicit
quality_score: 8.0
---

## Review Flags

### FLAG 1 — StakingMonthID MALFORMED BUG (HIGH)
**Severity**: High
**Description**: Two historical StakingMonthID values are 7 digits (2025030 = March 2025, 2024100 = October 2024) due to a LEFT(7) instead of LEFT(6) bug in older SP versions. These 7-digit values sort numerically *above* all valid 6-digit IDs, causing MAX(StakingMonthID) and ORDER BY StakingMonthID DESC to return incorrect months.
**Action**: Never use MAX(StakingMonthID) or ORDER BY StakingMonthID DESC. Use StakingYear + StakingMonth for temporal ordering. Add `WHERE LEN(CAST(StakingMonthID AS VARCHAR)) = 6` if StakingMonthID must be used as a filter.

### FLAG 2 — ETH OPT-IN DEFAULT IS DIFFERENT FROM OTHER COINS (MEDIUM)
**Severity**: Medium
**Description**: ETH staking is opt-in with default OFF, while all other coins (ADA, SOL, TRX, etc.) are opt-in with default ON (clients must explicitly opt out). This asymmetry means IsOptedIn_ETH = 0 does NOT mean the client didn't want to participate — it means they never explicitly opted in. ETH opt-in rates will always be significantly lower than other coin participation rates.
**Action**: When comparing ETH eligible position counts to other coins, note the opt-in mechanics. ETH pool size is genuinely smaller due to default-OFF, not just from a smaller eligible population.

### FLAG 3 — US CLIENT EXCLUSION ADDED IN SEPTEMBER 2025 (MEDIUM)
**Severity**: Medium
**Description**: Per SR-330593, a filter `AND ((is_us<>1) OR (is_us IS NULL))` was added to the SP in September 2025, explicitly excluding US clients from the staking pool. Data before September 2025 may include some US-regulation positions that would be excluded by the current SP logic.
**Action**: When comparing pre-Sept-2025 vs post-Sept-2025 data, note that the eligible pool composition changed. US-regulation clients (RegulationID IN (6,7,8)) should already be excluded by IsRegulationEligible, but the explicit is_us check adds an additional layer.

### FLAG 4 — PI EXCLUSION NOT IN IsClientEligible (LOW)
**Severity**: Low
**Description**: Popular Investors (IsPI=1) are excluded from staking, but this is reflected in NonEligible_PrimaryReason rather than a separate IsPI flag that gates IsClientEligible. When filtering eligible positions, `IsClientEligible = 1` correctly excludes PIs, but the reason is in NonEligible_PrimaryReason.
**Action**: No action needed for standard queries using `IsClientEligible = 1`. When analyzing ineligibility reasons, check for 'PI' or 'Popular Investor' in NonEligible_PrimaryReason.
