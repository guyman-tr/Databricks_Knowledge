# Review Needed: BI_DB_dbo.BI_DB_Index_Dividend_TaxReport

Generated: 2026-04-22 | Reviewer: Finance / Data Platform

## Tier 4 / Unverified Items

None — all columns have confirmed sources via SP code and upstream wiki.

## Questions for Business Reviewer

1. **TaxCode values**: What do the numeric codes represent? Values observed: 6, 40, 0, 999, 8, 998, 33, 1, 997, 996. Do 999/998/997/996 indicate error/special conditions vs standard tax codes?

2. **PositionType varchar(max)**: DDL declares this as `varchar(max)` but values are '0' and '1' (string representation of the numeric PositionType from `Trade.IndexDividends`). Is there a reason for varchar(max) vs int? Upstream source is tinyint.

3. **Negative TotalDividendPaid**: BT Group row shows TotalDividendPaid = -27.65. Is this a dividend correction/reversal or expected behavior? Should reports filter for positive amounts?

4. **SP_IndexDividend_Alert**: This table is read by `SP_IndexDividend_Alert` to flag dates with NULL BuyTax. What downstream action is taken on the alerts in `BI_DB_IndexDividends_Alert`?

5. **Regulation field for 'None'**: A small number of rows have Regulation='None' (1 row in 2026 data). Is this expected or a data quality issue?

## Known Data Quality Issues

- **SP name typo**: `SP_Index_Divident_TaxReport` ("Divident" not "Dividend") — cosmetic, functionality unaffected
- **`[Currency Name]` column with space**: Non-standard identifier requires bracket quoting in all queries
- **NULL columns before 2021-10-07**: IsBuy, ExDate, [Currency Name], TaxCode, EventType, BuyTax, Status all NULL for pre-2021 rows
- **PositionType as varchar(max)**: Type mismatch with upstream tinyint source — potential performance issue

## Lineage Confidence

| Column Group | Confidence | Source |
|-------------|------------|--------|
| PositionType, TaxCode, EventType, DividendValueInCurrency, DividendCurrencyID, BuyTax, Status, ExDate | HIGH (Tier 1) | Trade.IndexDividends upstream wiki |
| InstrumentDisplayName, ISINCode, [Currency Name] | HIGH (Tier 2) | DWH_dbo dimension tables |
| CountPositions, TotalDividendPaid, DateID, Regulation | HIGH (Tier 2) | SP code analysis |
| IsValidCustomer, IsCreditReportValidCB | MEDIUM (Tier 2) | Via Fact_SnapshotCustomer — standard DWH pattern |
