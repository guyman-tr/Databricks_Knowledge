---
object: Dealing_Commission_Assurance_By_Position
schema: Dealing_dbo
review_status: Pending
batch: 14
---

# Review Checklist — Dealing_Commission_Assurance_By_Position

## Automated Confidence Flags

| Flag | Detail |
|------|--------|
| ⚠️ Spread timing | Spread is taken from real-time External_Etoro_Trade_InstrumentSpread, not the spread at position open. Diffs may reflect market movement, not actual commission errors. |
| ⚠️ SellCurrencyID=1 filter | Only USD-denominated instruments. Non-USD instruments are excluded — is this intentional? |
| ℹ️ 90.8M rows | Large table — performance-sensitive. CCI + HASH(PositionID) is appropriate. |

## Questions for Reviewer

1. Is the real-time spread the correct reference for commission calculations, or should it use the spread at position open time?
2. Are non-USD instruments intentionally excluded, or is this a limitation?
3. What is the expected magnitude of `diff` values for normal operation? Is $0.0051 the right threshold?
4. Are negative diff values (undercharged) actionable, or only positive (overcharged)?

## Reviewer Corrections
<!-- Add corrections here. Format: FIELD: old value → new value. Mark [RESOLVED] when fixed. -->
