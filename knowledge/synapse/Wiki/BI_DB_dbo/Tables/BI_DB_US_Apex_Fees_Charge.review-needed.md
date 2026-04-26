# Review Needed: BI_DB_dbo.BI_DB_US_Apex_Fees_Charge

**Generated**: 2026-04-22 | **Batch**: 35 | **Quality**: 8.6/10

## Tier 4 Items (Require SME Validation)

- None — all columns are Tier 2 (SP code is clear source of truth).

## Open Questions

1. **FDFND (MM Purchase) is 61.3% of rows — is this table correctly named "Fees_Charge"?** The dominant event type is money market fund purchases ('MM Purchase'), which are fund transfers, not fees. Should analysts treat this as a general non-CA cash activity table rather than a fees-only table? Are FDFND events included for operational reconciliation or for business analysis?

2. **TerminalID meanings**: The TerminalID codes are documented from SP exclusion logic and sample data patterns but no official Apex TerminalID glossary was found. SME should confirm: SMFEE = paper statement fee, COFEE = paper confirmation fee, 9DACH = ACH disbursement, ACJRL = ?, 2TTFR = cash-to-margin transfer, 1TTFR = margin-to-cash transfer, L1RET = reverse ACH/NSF return, F7FND/FDFND = fund purchase variants?

3. **Z$ADR appears in both this table and CA_Apex**: ADR fees (Z$ADR TerminalID) are present here AND are not in the CA_Apex exclusion list. Are ADR fees included in both tables concurrently (double-counting risk) or do they appear in only one depending on context?

4. **AccountType '1' vs '2' distinction**: SP filters customer branch to AccountType IN ('1','2'). Based on CA_Apex context, '2' = margin account. What is '1'? Is it a cash/standard account? The AccountType column stores this as a varchar string from Apex.

5. **MSB account (3ET05007)**: Is '3ET05007' the only MSB omnibus account, or could additional MSB account numbers be added in future? The SP hardcodes this account number. If a second omnibus account were opened, the SP would need updating.

6. **ESJNL in customer rows (79 rows)**: ESJNL is not in the SP's excluded TerminalID list, so it appears in customer rows. Is ESJNL a journal entry (like OMJNL) that should be excluded but was missed?

## Cross-Object Consistency Notes

- This table and BI_DB_US_Apex_Corporate_CA_Apex both draw from the same Apex SOD869 source (External_Sodreconciliation_apex_EXT869_CashActivity). They are complementary: CA_Apex has dividend/CA TerminalIDs; this table has all other cash activity.
- CA_Apex applies Amount * -1 (sign flip); this table does NOT flip. Analysts comparing amounts across the two tables must apply a sign convention adjustment.
- Both tables are written daily by separate SPs (SP_US_Apex_Fees_Charge and SP_US_Apex_Corporate_Cash_Actions_Recon); ProcessDate coverage may differ slightly.

## Adversarial Evaluator Notes

Phase 16 evaluation target: 8.6/10 (expected PASS ≥ 7.5).
All 15 columns Tier 2. The Account column being ETL-derived (not from source) is correctly documented.
Main gap: TerminalID business semantics are inferred from Description samples and patterns rather than an authoritative Apex code glossary.
