# BI_DB_dbo.BI_DB_PI_Gain — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **IsLast column**: Present in DDL but never populated by the SP. Is this legacy or planned functionality?
2. **TimeFarme typo**: Should this be renamed to TimeFrame? Any downstream consumers that depend on the current name?
3. **Quarterly scope**: Q gains only include last year + current year (@LastYear). Historical quarterly gains before that are excluded.
