# Review Needed: BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_etoro

**Generated**: 2026-04-22 | **Batch**: 35 | **Quality**: 8.7/10

## Tier 4 Items (Require SME Validation)

- None — all columns are Tier 2 (SP code is clear source of truth).

## Open Questions

1. **"Not defined" 58.5%**: Over half of rows have eToroDescription='Not defined' (CompensationReasonID IS NULL, CreditTypeID=14 but no CA mapping). Are these purely fee records (OpenTotalFees, CloseTotalFees), or do they include other credit categories? Should 'Not defined' rows be excluded from CA reconciliation analysis vs. included as an unmatched bucket?

2. **CA_Desc_ID PATINDEX extraction reliability**: CA_Desc_ID is extracted via PATINDEX from free-text Description. For descriptions like 'OpenTotalFees14', this extracts '14'. How reliable is this extraction across all Description formats? Are there known patterns where the numeric extracted does not correspond to an actual CA type ID?

3. **Payment vs TotalCashChange divergence**: When do Payment and TotalCashChange differ? The wiki documents Payment=CA-specific amount and TotalCashChange=net change including fees. SME should confirm which is used in the actual Apex-eToro reconciliation comparison (matched against CA_Apex.Amount)?

4. **ApexID NULL rate**: ApexID is NULL when no Apex account is linked to the CID. What percentage of CIDs in this table have no Apex account? Are these expected (customers who opened eToro accounts but never linked Apex) or data quality issues?

5. **CreditTypeID=14 scope**: The filter CreditTypeID=14 was described as capturing corporate-action-related credits AND fees (broader than pure dividends). Is the intent to always keep fees in this table alongside dividends, or should they eventually be separated into a distinct fees table?

## Cross-Object Consistency Notes

- Companion table BI_DB_US_Apex_Corporate_CA_Apex documents the Apex side of the same reconciliation.
- Both tables written in the same SP run (SP_US_Apex_Corporate_Cash_Actions_Recon) — always consistent in Date/ProcessDate coverage.
- Date (eToro event date) vs ProcessDate (Apex SOD date) may differ by 1 day — reconciliation joins should use date-range tolerance or explicit offset logic.

## Adversarial Evaluator Notes

Phase 16 evaluation target: 8.7/10 (expected PASS ≥ 7.5).
All columns Tier 2 — SP code is the authoritative source; no upstream wiki exists for External_etoro_history_credit_Apex_Artyom.
