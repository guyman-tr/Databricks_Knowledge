# EXW_dbo.EXW_PaymentReconciliation — Review Notes

**Generated**: 2026-04-20  
**Batch**: 11  
**Quality Score**: 8.9/10

---

## Tier 4 Items (Reviewer Verification Needed)

| Column | Issue | Action Required |
|--------|-------|----------------|
| RealCID | Described as eToro platform ClientID mapped from GCID; exact mapping source not confirmed | Confirm: is RealCID = eToro CID (from eToroDB) vs GCID (from WalletDB)? Both have identical cardinality (29,775 distinct) — clarify whether they are different identifiers or aliases |
| SimplexAmountUSD | Documented as "normalized to USD" but exact derivation unclear — could be Simplex-provided USD value or ETL-calculated (SimplexAmountCurr × FX rate) | Confirm with ETL team which mechanism populates SimplexAmountUSD |
| SimplexProcessTime | Mapped to EXW_SimplexMapping.timestamp_created; could also be timestamp_required | Confirm which of the two SimplexMapping timestamps is used |
| bin_country / bank_name | Described as BIN lookup enrichment; the BIN lookup source is not documented in SSDT | Identify the BIN lookup table/service used for card-level country and bank enrichment |
| last_4_digits | Stored as numeric(18,0); source (ECP card_no_ extraction vs Simplex card data) not confirmed | Confirm whether last 4 are extracted from EXW_ECPBank.card_no_ or from a Simplex card field |
| UTI join | UTI links EXW_SimplexMapping.long_id → EXW_ECPBank.uti; UTI count (21,038) vs ECP count (20,944) = 94 payments have UTI but no ECP match | Investigate the 94 UTI-present / no-ECP-match gap: were these payments submitted to Simplex but not settled? |

## Data Quality Issues Documented

1. **ECPAmout column name typo** — Column is `ECPAmout` (not `ECPAmount`) — this is in the DDL itself. Any downstream queries must use the misspelled name. Documented in Section 3.4 Gotchas.
2. **167-payment gap vs EXW_FactPayments** — EXW_FactPayments has 99,410 distinct PaymentIDs; this table has 99,243 — 167 payments present in FactPayments but absent here. Cause unknown.
3. **bin_country "Unknown" = 56% of ECP-matched records** — BIN lookup coverage is poor; do not use bin_country as a reliable geography source without additional enrichment.
4. **ECPTranDate NULL for post-2020 records** — same behavior as EXW_ECPBank.transaction_date; only ECPPostDate is reliable.

## Open Questions

1. **Final status selection logic** — How does the ETL select which status event to retain as "final"? Is it the highest ModificationDate, the highest PaymentStatusId, or the terminal status in the state machine? Matters for IntimateCompleted/PendingTransaction rows that are not truly terminal states.
2. **GCID vs RealCID** — Both have 29,775 distinct values. If they always match in cardinality, why are both stored? Confirm whether there are rows where GCID ≠ RealCID.
3. **ETL pipeline identity** — No SSDT SP found for this table. Confirm the actual pipeline: ADF, bespoke Python job, or Generic Pipeline variant.
4. **SimplexAmountUSD for GBP payments** — Are GBP amounts converted to USD using a fixed rate, a daily FX rate, or Simplex's own USD quote? Relevant for historical USD revenue reporting.

## No Critical Blockers

All hard phase gates passed. Wiki is comprehensive for a 44-column cross-source reconciliation table with strong T1 coverage (16/44 = 36%) and good Phase 2+3 data evidence.
