---
object: Dealing_CapitalGuarantee
review_type: completeness
priority: low
---

# Review Notes — Dealing_CapitalGuarantee

## Items Needing Confirmation

1. **InitialAmount source**: The SP reads `IntitialAmount` (sic — typo in SP) from `general.etoroGeneral_History_GuruCopiers`. Confirm this is the copier's invested amount at the time copying started, not a snapshot of a later date.

2. **Post-expiry behavior**: After `@EndPromo = 20250101`, the SP continues running. Confirm whether the SP should be decommissioned now that the promotion has expired, or if there's a retention requirement for auditing.

3. **ActionTypeID disambiguation**: ActionTypeIDs 15 and 17 both add funds; ActionTypeID 16 removes funds. Confirm this mapping hasn't changed in Fact_CustomerAction as of 2025-2026 (Fact_CustomerAction ActionType dictionary).

4. **Eligibility_Ratio floor**: Can the ratio go below 0? Confirm whether a withdrawal larger than AUM is possible and whether the SP clips at 0.

5. **Protected_PnL for post-expiry rows**: For rows after 2025-01-01, is Protected_PnL still meaningful (internal tracking) or should it be filtered out in downstream reporting?

## No Blocking Issues

Promotion mechanics are well-documented. Low priority — promotion has already expired.
