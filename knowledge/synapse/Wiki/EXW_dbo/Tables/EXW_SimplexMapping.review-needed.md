# EXW_dbo.EXW_SimplexMapping — Review Notes

**Generated**: 2026-04-20  
**Batch**: 11  
**Quality Score**: 8.2/10

---

## Tier 4 Items (Reviewer Verification Needed)

| Column | Issue | Action Required |
|--------|-------|----------------|
| stage_drop | 35+ distinct Simplex-internal staging codes — coding scheme inferred from data patterns | Confirm numeric prefix semantics with payment ops team |
| card_debit_or_credit | Mixed card type values + risk engine error messages | Confirm data quality is known/acceptable or if sanitization is needed upstream |
| uti | UTI join to EXW_PaymentReconciliation on `UTI` column — verify exact join key (long_id vs uti) | Check EXW_PaymentReconciliation.UTI source in SP logic |
| long_id | Identified as the primary Simplex transaction GUID | Confirm this maps to EXW_SimplexChargebacks.Payment_ID format |

## Open Questions

1. **Is Simplex fully decommissioned?** processed_at_utc stops at 2022-09-19 but UpdateDate extends to 2024-04-09. Was ETL still running but receiving no new data, or did the provider relationship end? Document exact decommission date.
2. **Who owns this table?** No ETL SP in SSDT. Is this loaded by the data engineering team via ADF, or is it a Fivetran connection? Understanding the owner helps with data quality questions about `card_debit_or_credit` noise.
3. **total_amount_usd and total_amount stored as nvarchar** — was this intentional? Cast failures on non-numeric values are possible (the "-" empty pattern). Worth checking if any rows fail numeric cast.

## No Critical Blockers

All hard phase gates passed. Wiki is complete and accurate based on available data.
