# Review Needed — eMoney_Panel_Retention_Daily

**Batch**: 7  |  **Date**: 2026-04-20  |  **Reviewer**: —

---

## Tier 4 Items (None — all columns are Tier 2 from SP code)

No Tier 4 items. All 86 columns are traceable to SP_eMoney_Panel_Retention source code with full lineage.

---

## Open Questions

| # | Column(s) | Question | Priority |
|---|-----------|----------|----------|
| 1 | Amount_Tier_LT, TX_Tier_LT | Some customers show `Value_TotalActions_LT=0` but `Amount_Tier_LT=High_Active`. Likely the CASE expression's ELSE branch when ratio=0/0 (NULL). Confirm SP CASE logic handles this edge case explicitly or via ELSE clause default. | Low |
| 2 | ClubID=4 (Internal) | SP includes ClubID=4→Internal in ClubCategory CASE. No rows observed in sample. Confirm whether Internal accounts are filtered upstream (Fact_SnapshotCustomer) or if ClubID=4 simply doesn't exist in practice. | Low |
| 3 | CO terminology | "CO" is described as Cancel-Out (ActionTypeID=8 = Withdrawal). Confirm whether "Cancel-Out" is the official eMoney team terminology for this action type or if it should be called "Withdrawal" or "Money-Out". | Low |
| 4 | eMoney_Panel_FirstDates | Wiki files for eMoney_Panel_FirstDates are not on disk (batch 3 wrote context notes but no files found). If re-documenting, GCID/CID descriptions should be sourced from that wiki for cross-object consistency. | Medium |

---

## Reviewer Corrections

_None yet_

---

## Adversarial Evaluation Score

See Phase 16 output in session notes.
