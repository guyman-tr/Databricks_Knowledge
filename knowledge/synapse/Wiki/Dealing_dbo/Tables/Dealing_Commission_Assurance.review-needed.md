---
object: Dealing_Commission_Assurance
schema: Dealing_dbo
review_status: Pending
batch: 14
---

# Review Checklist — Dealing_Commission_Assurance

## Automated Confidence Flags

| Flag | Detail |
|------|--------|
| ⚠️ Stocks Manual Ratio ~0.98 | As of 2026-03, ~98% of Manual Stocks volume is commission-free. Is this expected (zero-commission real stocks model) or a data issue? |
| ⚠️ Max Rev Lost formula | $0.005 per position is hardcoded in SP. Is this the current baseline commission rate or a legacy value? |
| ℹ️ 612 rows total | Implies ~51 months × ~12 InstrumentType×Type combinations. Confirm no gaps. |

## Questions for Reviewer

1. Is a Ratio near 1.0 for Stocks Manual expected behavior (zero-commission product) or an alert condition?
2. What is the actual commission rate used in production — does the $0.005 `Max Rev Lost` formula still reflect current pricing?
3. Are there known instrument types that legitimately have zero commissions (e.g., ETFs, certain Crypto products)?
4. Who consumes this table — Dealing team, Finance, or compliance?

## Reviewer Corrections
<!-- Add corrections here. Format: FIELD: old value → new value. Mark [RESOLVED] when fixed. -->
