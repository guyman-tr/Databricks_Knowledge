# BI_DB_dbo.BI_DB_Affiliate_Report_90898 — Review Needed

## Tier 4 Items (require human verification)

| Column | Current Tier | Question |
|--------|-------------|----------|
| All columns | Tier 4 | No writer SP, no data — descriptions inferred from column names |

## Questions for Reviewer

1. **What is 90898?**: Is this an AffiliateID? A contract number? A regulation code?
2. **Decommission candidate**: 0 rows, no SP references. Should this table be dropped?
3. **SubSerialID**: What was stored in this varchar(1024) field? URL tracking parameters? Sub-account identifiers?
4. **PositionOpen**: Is this a count of positions or a boolean flag (0/1)?
5. **Historical context**: Was affiliate 90898 a significant partner? Was this report part of a contractual obligation?

## Dormant Table Assessment

- **Evidence**: 0 rows, no writer SP, no reader SP, no references in any SP
- **Per-affiliate pattern**: Having dedicated tables per affiliate is an anti-pattern that was likely cleaned up
- **Recommendation**: Strong candidate for DROP along with parent BI_DB_Affiliate_Report
