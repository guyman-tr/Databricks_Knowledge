# BI_DB_dbo.BI_DB_EOD_USD_cr — Review Needed

## Tier 4 Items

None — all columns traced to SP code or upstream wiki.

## Open Questions

1. **No downstream consumers**: No BI_DB SPs reference this table. Is it consumed by external reporting tools, Power BI dashboards, or ad-hoc queries? Understanding consumers would help determine if this table is still actively used.
2. **NULL conversion rates**: 2,858 rows have NULL USD_cr_Long/USD_cr_Short. These are instruments where no USD cross-rate path could be determined. Are these expected (exotic instruments) or data quality issues?
3. **InstrumentID count vs Fact_CurrencyPriceWithSplit**: This table has 15,415 distinct instruments vs 15,416 in the source — 1 instrument is missing. Is this expected (e.g., a system placeholder like InstrumentID=0)?

## Corrections for Reviewer

- InstrumentID description adapted from Dim_Instrument wiki (Tier 1 — Trade.Instrument). The original says "Primary key" but in this table it is used as an FK.
- USD_cr_Long/Short descriptions derived from SP code CASE logic. The cross-rate triangulation was traced through the self-JOIN pattern.
