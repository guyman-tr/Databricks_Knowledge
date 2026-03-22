---
object: Dealing_ESMANetLoss
schema: Dealing_dbo
review_status: Pending
batch: 14
---

# Review Checklist — Dealing_ESMANetLoss

## Automated Confidence Flags

| Flag | Detail |
|------|--------|
| ⚠️ ClosePositionReasonID=1 filter | Verify this is "natural close". If stop-triggered positions can also lose ≥95%, they are excluded — ESMA scope may be incomplete |
| ⚠️ NoProtectionRate source | Confirm PriceLog_History_CurrencyPrice always has a price at CloseOccurred for all instruments — sparse instruments may produce NULL |
| ⚠️ 95% threshold | ABS(NetProfit)/Amount≥0.95 — confirm this is the current ESMA regulatory threshold or if it has been updated |
| ℹ️ Regulation lookup | Confirm Dim_Regulation is keyed on CID and reflects regulation as-of CloseOccurred date (not current regulation) |

## Questions for Reviewer

1. Is `ClosePositionReasonID=1` the correct filter for "natural close" vs stop-triggered close? Could positions closed by stop-out also qualify for ESMA reporting?
2. Is the 95% loss threshold (ABS(NetProfit)/Amount≥0.95) still the current ESMA requirement, or has it been updated?
3. What happens when NoProtectionRate is NULL from PriceLog (e.g., illiquid instrument)? Is the row excluded or included with NULL DeltaLoss?
4. Is `EndForexPriceRateID=0` filter still necessary? What does a non-zero value indicate?
5. Does DeltaLoss = 0 or negative occur? If NoRestrictionNetProfit = NetProfit, does the row still appear?

## Reviewer Corrections
<!-- Add corrections here. Format: FIELD: old value → new value. Mark [RESOLVED] when fixed. -->
