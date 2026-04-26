# Review Needed: BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level

Generated: 2026-04-22 | Reviewer: Finance / Data Platform

## Tier 4 / Unverified Items

None — all columns have confirmed sources via SP code and upstream wiki.

## Questions for Business Reviewer

1. **TaxCode values**: Same question as parent `BI_DB_Index_Dividend_TaxReport` — do '999'/'998'/'997'/'996' indicate error/special conditions vs. standard tax codes? Combined with Country field, are there country-TaxCode combinations that are expected vs. anomalous?

2. **Country='None' rows**: Small number of rows (~1 in 2026 data) have Country='None'. Is this a data quality issue (Dim_Range SCD gap for that customer at @DateID) or a known edge case for certain customer types?

3. **CountPositions per customer**: This field counts positions for the specific RealCID only. For reporting: should consumers SUM CountPositions across RealCIDs to reconcile with parent table's CountPositions? Confirm aggregation intent.

4. **Table start date (Jan 2022)**: The parent table has history from Jan 2019, but this table only starts Jan 2022 (when SP was created with backfill to Jan 2022). Is the absence of 2019–2021 customer-level data intentional, or is there a backfill plan?

5. **HEAP index on 175M rows**: Unlike parent (clustered on DateID), this table is a HEAP. Are there plans to add a clustered index on DateID to improve performance for date-range scans? At this row count, full scans are expensive.

6. **Regulation='None' rows**: Inherited question from parent — are rows with Regulation='None' expected or a data quality issue?

## Known Data Quality Issues

- **SP name typo**: `SP_Index_Divident_TaxReport_CID_Level` ("Divident" not "Dividend") — cosmetic, functionality unaffected
- **`[Currency Name]` column with space**: Non-standard identifier requires bracket quoting in all queries
- **PositionType as varchar(max)**: Type mismatch with upstream tinyint source (same issue as parent)
- **Country='None' rows**: Small number where Dim_Range SCD resolution fails for customer at @DateID
- **HEAP distribution**: No clustered index for 175M-row table — date-range queries may be expensive

## Lineage Confidence

| Column Group | Confidence | Source |
|-------------|------------|--------|
| PositionType, TaxCode, EventType, DividendValueInCurrency, DividendCurrencyID, BuyTax, Status, ExDate | HIGH (Tier 1) | Trade.IndexDividends upstream wiki |
| RealCID | HIGH (Tier 1) | Customer.CustomerStatic upstream wiki via Dim_Customer |
| Country | HIGH (Tier 1) | Dictionary.Country via Dim_Country wiki + SP code confirms chain |
| InstrumentDisplayName, ISINCode, [Currency Name] | HIGH (Tier 2) | DWH_dbo dimension tables |
| CountPositions, TotalDividendPaid, DateID, Regulation | HIGH (Tier 2) | SP code analysis |
| IsValidCustomer, IsCreditReportValidCB | MEDIUM (Tier 2) | Via Fact_SnapshotCustomer — standard DWH pattern |
