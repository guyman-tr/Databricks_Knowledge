---
object: Dealing_Staking_Results
schema: Dealing_dbo
type: table
batch: 12
review_flags:
  - stakingmonthid_malformed_bug
  - airdrop_fields_null_before_distribution
  - ineligible_rows_included
  - rounding_discrepancy_actualunits
quality_score: 8.5
---

## Review Flags

### FLAG 1 — StakingMonthID MALFORMED BUG (HIGH)
**Severity**: High
**Description**: `2024100` (Oct 2024) and `2025100` (Oct 2025) are 7-digit IDs due to historical LEFT(7) SP bug. These sort above all valid 6-digit IDs. MAX(StakingMonthID) returns 2025100 not the actual latest month.
**Action**: Use `StakingYear + StakingMonth` for temporal filtering. Add `WHERE LEN(CAST(StakingMonthID AS VARCHAR)) = 6` when StakingMonthID is used as a key.

### FLAG 2 — AIRDROP FIELDS ARE NULL BEFORE DISTRIBUTION (MEDIUM)
**Severity**: Medium
**Description**: `AirdropID`, `AirdropOccurred`, `IsAirdropSuccess`, `FailReasonID`, `ActualAirdropUnits`, and `ActualCompensationType` are all NULL until the distribution process runs. The initial SP insert populates only reward allocation fields. NULL in `IsAirdropSuccess` does NOT mean failure — it means the airdrop has not been attempted yet.
**Action**: When filtering for delivered rewards, use `IsAirdropSuccess = 1` (not IS NOT NULL). When checking if an airdrop has run, check `AirdropOccurred IS NOT NULL`.

### FLAG 3 — INELIGIBLE CLIENTS INCLUDED IN TABLE (MEDIUM)
**Severity**: Medium
**Description**: Rows with `IsEligible = 0` are included in the table (with `NonEligible_PrimaryReason` populated and `Client_Airdrop = 0` or NULL). Aggregate queries without `WHERE IsEligible = 1` will include ineligible clients and undercount per-client rewards or overcount client counts.
**Action**: Always add `WHERE IsEligible = 1` when calculating pool metrics, reward totals, or eligible client counts.

### FLAG 4 — ActualAirdropUnits MAY DIFFER FROM Client_Airdrop (LOW)
**Severity**: Low
**Description**: Due to rounding at the airdrop execution layer, `ActualAirdropUnits` may differ slightly from `Client_Airdrop`. For financial reconciliation (e.g., eToro vs client split), use `ActualAirdropUnits` after distribution; use `Client_Airdrop` for planning/pre-distribution analysis.
**Action**: For post-distribution reporting, prefer `ActualAirdropUnits` over `Client_Airdrop`. Note the discrepancy in any reconciliation reports.
