---
object: Dealing_Daily_Slippage_Positions_TriggerVSReceived
schema: Dealing_dbo
type: table
batch: 11
review_flags:
  - pipeline_gap
  - pii_present
  - ibuy_inversion
quality_score: 8.0
---

## Review Flags

### FLAG 1 — PIPELINE GAP (MEDIUM)
**Severity**: Medium
**Description**: Table last updated 2025-01-11 (~2.5 months stale). SP_Slippage_Report scheduling appears to have stopped. No known data feed dependency explains this.
**Action**: Check ADF/orchestration schedule for `SP_Slippage_Report`. Both TVR and non-TVR tables (Totals, Positions) all stopped at the same Jan 2025 date.

### FLAG 2 — PII PRESENT (HIGH)
**Severity**: High
**Description**: Column `CID` (customer ID) is present in this table. Any query returning this column must comply with data classification and access control policies.
**Action**: Confirm data masking/RLS is applied for this table in BI reporting layers. Document data retention policy.

### FLAG 3 — IsBuy INVERSION FOR CLOSED POSITIONS (MEDIUM)
**Severity**: Medium
**Description**: In `#Closed`, `IsBuy` is deliberately **inverted** (`CASE WHEN HP.IsBuy=1 THEN 0 ELSE 1 END`) while `OrigIsBuy` preserves the original direction. This means for a position that was originally a Buy and is now being closed, `IsBuy=0` in the table. The slippage formula `(IsBuy=1?+1:-1)` uses this inverted value, which correctly captures the direction of the closing trade.
**Action**: Ensure any analysis using `IsBuy` for "original position direction" uses `OrigIsBuy` instead. Document this convention for consumers.

### FLAG 4 — RequestOccurred_CustomerChosenRate NULL FALLBACK (LOW)
**Severity**: Low
**Description**: When `RequestOccurred_CustomerChosenRate IS NULL` (PriceLog CROSS APPLY returned no match), the code falls back to `CustomerChosenRate`. In those cases, the "TVR" columns are effectively identical to the non-TVR values. This means `RequestOccurred_SlippageInDollar` may not always represent the true TVR metric.
**Action**: Quantify the NULL rate for `RequestOccurred_CustomerChosenRate`. High NULL rate would indicate the TVR metric has limited coverage.
