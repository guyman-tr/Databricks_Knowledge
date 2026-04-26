# BI_DB_dbo.BI_DB_InterestMonthly — Review Needed

## Tier 4 Items

None — no Tier 4 descriptions in this wiki.

## Review Questions

1. **Column name typo**: `FinalTaxedlnterest` uses lowercase 'l' instead of uppercase 'I'. This is inherited from the source. Should this be corrected in a future DDL change?

2. **Interest database wiki**: No upstream wiki exists for the Interest database (`Interest.Trade.InterestMonthly`). If one is created, columns could be upgraded to Tier 1.

3. **StatusID semantics**: Only StatusID=3 exists in this table. What do other StatusID values mean in the source (1=pending? 2=rejected?)? This would help document the filtering logic.

## Reviewer Corrections

None yet.
