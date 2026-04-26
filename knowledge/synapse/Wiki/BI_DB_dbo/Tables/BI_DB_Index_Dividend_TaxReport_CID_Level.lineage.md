# Lineage: BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level

**Writer SP**: `BI_DB_dbo.SP_Index_Divident_TaxReport_CID_Level` (author: Tal Buhnik, 2022-09-08; "Divident" typo in SP name)  
**Load Pattern**: DELETE WHERE DateID=@DateID + INSERT (date-keyed incremental)  
**Primary Source**: `BI_DB_dbo.BI_DB_DailyDividendsByPosition` (position-level dividend rows for @DateID)  
**Secondary Sources**: `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Currency`, `DWH_dbo.etoro_Trade_IndexDividends` (→ `etoro.Trade.IndexDividends`), `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Range`, `DWH_dbo.Dim_Country`

**Parent Table**: `BI_DB_dbo.BI_DB_Index_Dividend_TaxReport` — same columns + RealCID + Country (CID-level grain)

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | DividendID | BI_DB_DailyDividendsByPosition | DividendID | Passthrough | Tier 2 |
| 2 | InstrumentID | BI_DB_DailyDividendsByPosition | InstrumentID | Passthrough | Tier 2 |
| 3 | InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | JOIN on InstrumentID | Tier 2 |
| 4 | ISINCode | DWH_dbo.Dim_Instrument | ISINCode | JOIN on InstrumentID | Tier 2 |
| 5 | PositionType | BI_DB_DailyDividendsByPosition | PositionType | Passthrough ← etoro_Trade_IndexDividends | Tier 1 |
| 6 | TaxCode | BI_DB_DailyDividendsByPosition | TaxCode | Passthrough ← etoro_Trade_IndexDividends | Tier 1 |
| 7 | EventType | BI_DB_DailyDividendsByPosition | EventType | Passthrough ← etoro_Trade_IndexDividends | Tier 1 |
| 8 | PaymentDate | BI_DB_DailyDividendsByPosition | Date | Rename ([Date] → PaymentDate); CAST(Fact_CustomerAction.Occurred AS DATE) | Tier 2 |
| 9 | DividendValueInCurrency | BI_DB_DailyDividendsByPosition | DividendValueInCurrency | Passthrough ← etoro_Trade_IndexDividends | Tier 1 |
| 10 | DividendCurrencyID | BI_DB_DailyDividendsByPosition | DividendCurrencyID | Passthrough ← etoro_Trade_IndexDividends | Tier 1 |
| 11 | BuyTax | BI_DB_DailyDividendsByPosition | BuyTax | Passthrough ← etoro_Trade_IndexDividends | Tier 1 |
| 12 | Status | BI_DB_DailyDividendsByPosition | Status | Passthrough ← etoro_Trade_IndexDividends | Tier 1 |
| 13 | DateID | BI_DB_DailyDividendsByPosition | DateID | Passthrough — YYYYMMDD int of payment day | Tier 2 |
| 14 | Regulation | BI_DB_DailyDividendsByPosition | Regulation | Passthrough ← Dim_Regulation.Name | Tier 2 |
| 15 | CountPositions | BI_DB_DailyDividendsByPosition | PositionID | ISNULL(COUNT(PositionID), 0) GROUP BY (per RealCID) | Tier 2 |
| 16 | TotalDividendPaid | BI_DB_DailyDividendsByPosition | Amount | ISNULL(SUM(Amount), 0) GROUP BY (per RealCID) | Tier 2 |
| 17 | IsValidCustomer | BI_DB_DailyDividendsByPosition | IsValidCustomer | Passthrough ← Fact_SnapshotCustomer.IsValidCustomer at @DateID | Tier 2 |
| 18 | IsCreditReportValidCB | BI_DB_DailyDividendsByPosition | IsCreditReportValidCB | Passthrough ← Fact_SnapshotCustomer.IsCreditReportValidCB at @DateID | Tier 2 |
| 19 | UpdateDate | ETL | GETDATE() | Batch timestamp | Tier 3 |
| 20 | IsBuy | BI_DB_DailyDividendsByPosition | IsBuy | Passthrough ← Dim_Position.IsBuy | Tier 2 |
| 21 | ExDate | DWH_dbo.etoro_Trade_IndexDividends | ExDate | LEFT JOIN on DividendID — ex-dividend date from Trade.IndexDividends | Tier 1 |
| 22 | [Currency Name] | DWH_dbo.Dim_Currency | Abbreviation | JOIN on DividendCurrencyID | Tier 2 |
| 23 | RealCID | BI_DB_DailyDividendsByPosition | RealCID | Passthrough ← Fact_CustomerAction.RealCID ← Customer.CustomerStatic.CID | Tier 1 |
| 24 | Country | DWH_dbo.Dim_Country | Name | JOIN Fact_SnapshotCustomer + Dim_Range + Dim_Country on CountryID at @DateID | Tier 1 |

## ETL Pipeline

```
etoro.Trade.IndexDividends (production OLTP)
  |-- Generic Pipeline (Bronze) ---|
  v
DWH_dbo.etoro_Trade_IndexDividends (External Table)
                    |
BI_DB_dbo.BI_DB_DailyDividendsByPosition (position-level dividends)
  |-- SP_Index_Divident_TaxReport_CID_Level @Date ---|
  |   (JOIN Dim_Instrument, Dim_Currency, etoro_Trade_IndexDividends)
  |   (JOIN Fact_SnapshotCustomer + Dim_Range + Dim_Country for Country)
  v
BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level (~175M rows, Jan 2022–Apr 2026)
  |-- (No UC target — Not Migrated) ---|
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 10 | PositionType, TaxCode, EventType, DividendValueInCurrency, DividendCurrencyID, BuyTax, Status, ExDate, RealCID, Country |
| Tier 2 | 13 | DividendID, InstrumentID, InstrumentDisplayName, ISINCode, PaymentDate, DateID, Regulation, CountPositions, TotalDividendPaid, IsValidCustomer, IsCreditReportValidCB, IsBuy, [Currency Name] |
| Tier 3 | 1 | UpdateDate |
