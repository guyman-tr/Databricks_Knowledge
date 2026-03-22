# Column Lineage -- BI_DB_dbo.BI_DB_Daily_Dividends

**Writer SP**: `BI_DB_dbo.SP_Daily_Dividends` (Priority 99 -- FinanceReportSPS)
**ETL Pattern**: DELETE-INSERT by Date
**Architecture**: #div (raw dividends) -> #temp (enriched) -> aggregated INSERT

---

## Source Tables

| Source | Alias | Role |
|--------|-------|------|
| DWH_dbo.Fact_CustomerAction | (none) | Primary -- dividend actions (ActionTypeID=35, IsFeeDividend=2) |
| DWH_dbo.Dim_Position | b | Position details (InstrumentID, IsSettled) |
| DWH_dbo.Dim_Instrument | c | Instrument metadata |
| DWH_dbo.Fact_SnapshotCustomer | sc | Customer regulation, validity |
| DWH_dbo.Dim_Range | r | Date range resolution |
| DWH_dbo.Dim_Regulation | dr | Regulation name |
| BI_DB_dbo.BI_DB_US_Stocks | e | US stock classification (LEFT JOIN) |

---

## Column-Level Lineage

**Alias-level source attribution applied** -- two-step: #div -> #temp -> final aggregated INSERT.

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| Regulation | Dim_Regulation (dr) | Name | Direct via sc.RegulationID = dr.DWHRegulationID |
| Date | #div (a) | Date | CAST(Occurred as date) from Fact_CustomerAction |
| InMonthWeekNumber | computed | Date | CASE: DAY 1-7=1, 8-15=2, 16-22=3, 23+=4 |
| Is_US_Stock | BI_DB_US_Stocks (e) | InstrumentID existence | CASE WHEN e.InstrumentID IS NOT NULL THEN 1 ELSE 0 END |
| Instrument_segment | computed | InstrumentTypeID, IsSettled, Regulation | CASE: Real_Stocks/Real_ETF/CFD_Stocks/CFD_ETF/Other |
| ISINCode | Dim_Instrument (c) | ISINCode | Direct |
| InstrumentID | Dim_Position (b) | InstrumentID | Direct |
| InstrumentName | Dim_Instrument (c) | InstrumentDisplayName | Direct |
| Symbol | Dim_Instrument (c) | Name | Direct |
| Exchange | Dim_Instrument (c) | Exchange | Direct |
| DividendPaid | Fact_CustomerAction | Amount | SUM(Dividend) via #div. Originally Fact_CustomerAction.Amount |
| UpdateDate | computed | GETDATE() | SP execution timestamp |
| IsValidCustomer | Fact_SnapshotCustomer (sc) | IsValidCustomer | Direct |
| IsCreditReportValidCB | Fact_SnapshotCustomer (sc) | IsCreditReportValidCB | Direct |
