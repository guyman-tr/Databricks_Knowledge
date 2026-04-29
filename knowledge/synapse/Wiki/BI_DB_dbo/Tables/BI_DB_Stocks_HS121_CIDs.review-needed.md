# BI_DB_dbo.BI_DB_Stocks_HS121_CIDs — Review Needed

## Questions for Reviewer

1. 32.75B rows — is there a retention policy? This is one of the largest BI_DB tables.
2. SP name is SP_Stocks_HS125 but table is HS121_CIDs — should the SP be renamed for clarity?
3. DDL has 13 columns but batch assignment listed 14 — verify no column missing.
4. ClosingPrice is Bid from Fact_CurrencyPriceWithSplit — is Ask price needed for short positions?
5. HedgeServerID list was expanded over time (9→10 servers) — are all still active?

## Validation Notes

- Column count: 13 DDL = 13 wiki elements (MATCH)
- All 8 sections present
- Tier distribution: 1 T1, 10 T2, 0 T3, 0 T4, 2 T5
