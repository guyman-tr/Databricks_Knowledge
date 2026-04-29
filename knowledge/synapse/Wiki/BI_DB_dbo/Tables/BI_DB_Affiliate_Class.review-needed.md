# BI_DB_dbo.BI_DB_Affiliate_Class — Review Needed

## Tier 4 Items (require human verification)

| Column | Current Tier | Question |
|--------|-------------|----------|
| All columns | Tier 4 | No writer SP, no data, no references — all descriptions purely inferred from DDL |

## Questions for Reviewer

1. **Decommission candidate**: 0 rows, no writer SP, no reader SP, no references. Should this table be dropped?
2. **Class values**: What classification tiers were used? Gold/Silver/Bronze? A/B/C? Numeric tiers?
3. **Historical context**: Was this ever populated on on-prem BI_DB? If so, what replaced it?

## Dormant Table Assessment

- **Evidence of dormancy**: 0 rows, no writer SP, no reader SP, no references in any SP
- **Stronger signal than BI_DB_AffData**: At least AffData had PII masking references; this table has literally zero references
- **Recommendation**: Strong candidate for blacklist or DROP
