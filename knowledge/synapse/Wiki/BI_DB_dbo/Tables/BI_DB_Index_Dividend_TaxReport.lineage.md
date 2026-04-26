# Lineage: BI_DB_dbo.BI_DB_Index_Dividend_TaxReport

**Writer SP**: `BI_DB_dbo.SP_Index_Divident_TaxReport` (note: "Divident" typo in SP name)  
**Load Pattern**: DELETE WHERE DateID=@DateID + INSERT (date-keyed incremental)  
**Primary Source**: `BI_DB_dbo.BI_DB_DailyDividendsByPosition` (position-level dividend rows for @DateID)  
**Secondary Sources**: `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Currency`, `DWH_dbo.etoro_Trade_IndexDividends` (→ `etoro.Trade.IndexDividends`)

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
| 8 | PaymentDate | BI_DB_DailyDividendsByPosition | Date | Rename ([Date] → PaymentDate); CAST(Fact_CustomerAction.Occurred AS DATE) on payment day | Tier 2 |
| 9 | DividendValueInCurrency | BI_DB_DailyDividendsByPosition | DividendValueInCurrency | Passthrough ← etoro_Trade_IndexDividends | Tier 1 |
| 10 | DividendCurrencyID | BI_DB_DailyDividendsByPosition | DividendCurrencyID | Passthrough ← etoro_Trade_IndexDividends | Tier 1 |
| 11 | BuyTax | BI_DB_DailyDividendsByPosition | BuyTax | Passthrough ← etoro_Trade_IndexDividends (ISNULL coalesce with PositionsProcessedForIndexDividnds) | Tier 1 |
| 12 | Status | BI_DB_DailyDividendsByPosition | Status | Passthrough ← etoro_Trade_IndexDividends. DWH note: only Status=2 (completed) rows enter via DailyDividendsByPosition filter | Tier 1 |
| 13 | DateID | BI_DB_DailyDividendsByPosition | DateID | Passthrough — YYYYMMDD int of payment day | Tier 2 |
| 14 | Regulation | BI_DB_DailyDividendsByPosition | Regulation | Passthrough ← Dim_Regulation.Name | Tier 2 |
| 15 | CountPositions | BI_DB_DailyDividendsByPosition | PositionID | ISNULL(COUNT(PositionID), 0) GROUP BY — count of position rows with this dividend on @DateID | Tier 2 |
| 16 | TotalDividendPaid | BI_DB_DailyDividendsByPosition | Amount | ISNULL(SUM(Amount), 0) GROUP BY — total dividend amount paid across positions | Tier 2 |
| 17 | IsValidCustomer | BI_DB_DailyDividendsByPosition | IsValidCustomer | Passthrough ← Fact_SnapshotCustomer.IsValidCustomer at @DateID | Tier 2 |
| 18 | IsCreditReportValidCB | BI_DB_DailyDividendsByPosition | IsCreditReportValidCB | Passthrough ← Fact_SnapshotCustomer.IsCreditReportValidCB at @DateID | Tier 2 |
| 19 | UpdateDate | ETL | GETDATE() | Batch timestamp | Tier 3 |
| 20 | IsBuy | BI_DB_DailyDividendsByPosition | IsBuy | Passthrough ← Dim_Position.IsBuy | Tier 2 |
| 21 | ExDate | DWH_dbo.etoro_Trade_IndexDividends | ExDate | LEFT JOIN on DividendID — ex-dividend date from Trade.IndexDividends | Tier 1 |
| 22 | [Currency Name] | DWH_dbo.Dim_Currency | Abbreviation | JOIN on DividendCurrencyID — currency abbreviation code | Tier 2 |

## ETL Pipeline

```
etoro.Trade.IndexDividends (production)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_dbo.etoro_Trade_IndexDividends (External Table)
  |-- SP_Index_Divident_TaxReport @Date ---|  [also reads BI_DB_DailyDividendsByPosition]
  v
BI_DB_dbo.BI_DB_Index_Dividend_TaxReport (934K rows, Jan 2019–Apr 2026)
  |-- (no UC target — Not Migrated) ---|
```

## Source Objects

| Object | Schema | Type | Role |
|--------|--------|------|------|
| BI_DB_DailyDividendsByPosition | BI_DB_dbo | Table | Primary data source — position-level dividend rows |
| etoro_Trade_IndexDividends | DWH_dbo | External Table | ExDate join source → etoro.Trade.IndexDividends |
| Dim_Instrument | DWH_dbo | Table | InstrumentDisplayName + ISINCode enrichment |
| Dim_Currency | DWH_dbo | Table | Currency name (Abbreviation) enrichment |

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 7 | PositionType, TaxCode, EventType, DividendValueInCurrency, DividendCurrencyID, BuyTax, Status, ExDate (8 — see note) |
| Tier 2 | 13 | DividendID, InstrumentID, InstrumentDisplayName, ISINCode, PaymentDate, DateID, Regulation, CountPositions, TotalDividendPaid, IsValidCustomer, IsCreditReportValidCB, IsBuy, [Currency Name] |
| Tier 3 | 1 | UpdateDate |
| Tier 4 | 0 | — |

*Note: ExDate = Tier 1. Total Tier 1 = 8 columns (PositionType, TaxCode, EventType, DividendValueInCurrency, DividendCurrencyID, BuyTax, Status, ExDate).*
