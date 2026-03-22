# Column Lineage -- BI_DB_dbo.BI_DB_Real_Crypto_Loan

**Writer SP**: `BI_DB_dbo.SP_Real_Crypto_Loans` (Priority 99 -- FinanceReportSPS)
**Author**: Guy Manova (2021-10-01)
**ETL Pattern**: DELETE-INSERT by Date (month-end only)
**Conditional**: Only executes when @IsEndOfMonth = 'Y'

---

## Source Tables

| Source | Alias | Role |
|--------|-------|------|
| BI_DB_dbo.BI_DB_PositionPnL | bdppl | Primary -- current position state (units, amount) |
| DWH_dbo.Dim_Position | dp | Initial position data (InitialUnits, InitialAmountCents) |
| DWH_dbo.Dim_Instrument | di | Instrument name, crypto filter (InstrumentTypeID=10) |
| DWH_dbo.Fact_SnapshotCustomer | fsc | Customer validity + regulation |
| DWH_dbo.Dim_Range | dr | Date range resolution |
| DWH_dbo.Dim_Regulation | dr1 | Regulation name |

---

## Column-Level Lineage

**Alias-level source attribution applied** -- #pos -> #assetlevel -> INSERT.

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| Date | computed | @date | CAST(@date AS DATE) |
| InstrumentID | BI_DB_PositionPnL (bdppl) | InstrumentID | Direct. Filtered: >= 100000 (crypto) |
| Instrument | Dim_Instrument (di) | Name | LEFT JOIN on bdppl.InstrumentID |
| IsSettled | BI_DB_PositionPnL (bdppl) | IsSettled | Direct. Always 1 (filter condition) |
| Leverage | BI_DB_PositionPnL (bdppl) | Leverage | Direct. Always 2 (filter condition) |
| InitialUnits | Dim_Position (dp) | InitialUnits | SUM. Original crypto units at position opening |
| CurrentUnits | BI_DB_PositionPnL (bdppl) | AmountInUnitsDecimal | SUM. Current crypto units |
| InitialAmountCryptoLoan | Dim_Position (dp) | InitialAmountCents | SUM(InitialAmountCents/100). Converts cents to USD |
| CurrentAmountCryptoLoan | BI_DB_PositionPnL (bdppl) | Amount | SUM. Current market value |
| UpdateDate | computed | GETDATE() | SP execution timestamp |
| Regulation | Dim_Regulation (dr1) | Name | Direct via fsc.RegulationID = dr1.DWHRegulationID |
