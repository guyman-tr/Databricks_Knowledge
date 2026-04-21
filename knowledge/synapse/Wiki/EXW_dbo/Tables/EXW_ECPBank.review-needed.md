# EXW_dbo.EXW_ECPBank — Review Notes

**Generated**: 2026-04-20  
**Batch**: 11  
**Quality Score**: 8.6/10

---

## Tier 4 Items (Reviewer Verification Needed)

| Column | Issue | Action Required |
|--------|-------|----------------|
| fpi | 3-char code described as "Funding/Product Indicator" from card scheme interchange tables | Confirm with payment ops whether FPI = "Funding and Product Indicator" (standard ECP term) |
| internal_batch_no_ | Stored as float with pattern YYYYMMDDBATCH.0 inferred from sample data | Confirm interpretation with ECP Bank integration team |
| acquirer_bin_ica | 453760=Visa, 14206=Mastercard inferred from card brand patterns in EXW_SimplexChargebacks | Verify BIN→network mapping |
| cross_rate | Stored as bigint despite containing decimal-like values in samples | Confirm if this is a rate × 10000 or similar scaled integer encoding |

## Data Quality Issues Documented

1. **merchant_no_ formatting inconsistency** — 3 variants in data. Documents which one is canonical.
2. **transaction_date NULL for newer records** — only posting_date reliable. Documented in gotchas.
3. **_fivetran_deleted semantics** — True/False stored as bit but displayed as "True"/"False" strings. May cause WHERE issues in some SQL clients.

## Open Questions

1. **Was ECP Bank the only acquirer?** acquirer_bin_ica shows only 453760 (Visa) and 14206 (Mastercard). Were AMEX or Discover ever supported through this channel?
2. **What is "eMP" in batch_no_?** Could stand for "eMerchant Payment" or similar. Clarify.
3. **UpdateDateID is NULL** — Was this column intended to be populated? Appears as an ETL-derived field that was never backfilled.

## No Critical Blockers

All hard phase gates passed. Wiki is comprehensive for a 33-column Fivetran-loaded settlement table.
