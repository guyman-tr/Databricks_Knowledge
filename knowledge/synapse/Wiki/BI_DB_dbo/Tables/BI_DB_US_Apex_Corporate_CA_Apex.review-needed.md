# Review Needed: BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_Apex

**Generated**: 2026-04-22 | **Batch**: 35 | **Quality**: 8.7/10

## Tier 4 Items (Require SME Validation)

- None — all columns are Tier 2 (SP code is clear source of truth).

## Open Questions

1. **NULL eToroDescription (8%)**: 36,374 rows have CompensationReasonID IS NULL and eToroDescription IS NULL. What are these TerminalIDs? Should they be mapped or excluded from CA reconciliation?

2. **NULL eToroCID (2.4%)**: 10,750 rows have no matched eToro CID. Are these former customers, test accounts, or data quality issues? Are they included or excluded from reconciliation analysis?

3. **Amount sign convention**: Confirmed as sign-flipped (Amount * -1). SME should verify this is the intended behavior for downstream consumption — analysts may be confused by positive = received.

4. **ProcessDate vs effective date**: SOD869 processing date may lag actual CA effective date. Is this table used for cash-basis accounting or accrual-basis accounting purposes?

5. **'OMJNL' exclusion**: Journal entries with TerminalID='OMJNL' are excluded. Are these documented elsewhere?

## Cross-Object Consistency Notes

- Companion table BI_DB_US_Apex_Corporate_CA_etoro documents the eToro side of the same reconciliation.
- Both tables written in the same SP run — always consistent in ProcessDate coverage.

## Adversarial Evaluator Notes

Phase 16 evaluation target: 8.7/10 (expected PASS ≥ 7.5).
All columns Tier 2 — no upstream wiki exists for Apex SOD869 external sources.
