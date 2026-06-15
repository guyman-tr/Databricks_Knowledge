# BI_DB_dbo.BI_DB_Daily_Dividends

## 1. Overview

Daily aggregated **dividend payments** by instrument. Each row represents the total dividends paid for a specific instrument on a specific date, broken down by regulation, settlement type (Real vs CFD), and US stock classification. Used by finance for dividend reconciliation and reporting.

**Row grain**: Regulation + Date + InstrumentID + InMonthWeekNumber + Instrument_segment + IsValidCustomer + IsCreditReportValidCB

---

## 2. Business Context

Tracks dividend payments credited to customers via `Fact_CustomerAction` (ActionTypeID=35, IsFeeDividend=2). Dividends are categorized by instrument segment to distinguish between real stock/ETF dividends and CFD dividend adjustments.

**Key business rules**:
- **Dividend source**: `Fact_CustomerAction` with `ActionTypeID = 35` and `IsFeeDividend = 2`. Amount is aggregated per instrument.
- **Instrument_segment classification**:
  - `Real_Stocks`: InstrumentTypeID=5, IsSettled=1, Regulation != ASIC
  - `Real_ETF`: InstrumentTypeID=6, IsSettled=1, Regulation != ASIC
  - `CFD_Stocks`: InstrumentTypeID=5, IsSettled=0 OR (IsSettled=1 AND Regulation=ASIC)
  - `CFD_ETF`: InstrumentTypeID=6, IsSettled=0 OR (IsSettled=1 AND Regulation=ASIC)
  - `Other`: everything else
- **ASIC exception**: Under ASIC regulation, even settled positions are treated as CFD for dividend classification.
- **Is_US_Stock**: 1 if InstrumentID exists in `BI_DB_US_Stocks` lookup table.
- **InMonthWeekNumber**: 1-4 based on day of month (1-7, 8-15, 16-22, 23+).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 14 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Regulation | varchar(50) | NO | Regulation name from Dim_Regulation.Name. NOT NULL. (Tier 2 -SP_Daily_Dividends, Dim_Regulation.Name) |
| 2 | Date | date | NO | Calendar date of dividend payment. Clustered index. NOT NULL. (Tier 2 -SP_Daily_Dividends, @dd) |
| 3 | InMonthWeekNumber | int | NO | Week within month: 1 (days 1-7), 2 (8-15), 3 (16-22), 4 (23+). (Tier 2 -SP_Daily_Dividends, computed from DAY()) |
| 4 | Is_US_Stock | tinyint | YES | Flag: 1 if InstrumentID in BI_DB_US_Stocks. US tax reporting relevance. (Tier 2 -SP_Daily_Dividends, BI_DB_US_Stocks) |
| 5 | Instrument_segment | varchar(50) | YES | Classification: "Real_Stocks", "Real_ETF", "CFD_Stocks", "CFD_ETF", "Other". Based on InstrumentTypeID, IsSettled, and Regulation. (Tier 2 -SP_Daily_Dividends, computed) |
| 6 | ISINCode | varchar(50) | YES | ISIN code from Dim_Instrument.ISINCode. International Securities Identification Number. (Tier 2 -SP_Daily_Dividends, Dim_Instrument.ISINCode) |
| 7 | InstrumentID | int | YES | Instrument identifier from Dim_Position.InstrumentID. (Tier 2 -SP_Daily_Dividends, Dim_Position.InstrumentID) |
| 8 | InstrumentName | varchar(100) | YES | Display name from Dim_Instrument.InstrumentDisplayName. (Tier 2 -SP_Daily_Dividends, Dim_Instrument.InstrumentDisplayName) |
| 9 | Symbol | varchar(50) | YES | Trading symbol from Dim_Instrument.Name. Values: "AAPL/USD", "ABBV/USD", etc. (Tier 2 -SP_Daily_Dividends, Dim_Instrument.Name) |
| 10 | Exchange | varchar(max) | YES | Exchange name from Dim_Instrument.Exchange. Values: "NYSE", "NASDAQ", "CFD", etc. (Tier 2 -SP_Daily_Dividends, Dim_Instrument.Exchange) |
| 11 | DividendPaid | decimal(16,8) | YES | Total dividend amount paid for this instrument on this date. SUM(Dividend) aggregated from Fact_CustomerAction.Amount. (Tier 2 -SP_Daily_Dividends, Fact_CustomerAction.Amount) |
| 12 | UpdateDate | datetime | YES | SP execution timestamp. GETDATE(). (Tier 3 -SP_Daily_Dividends, GETDATE()) |
| 13 | IsValidCustomer | int | YES | Customer validity flag from Fact_SnapshotCustomer. (Tier 2 -SP_Daily_Dividends, Fact_SnapshotCustomer.IsValidCustomer) |
| 14 | IsCreditReportValidCB | int | YES | Credit report validity flag from Fact_SnapshotCustomer. (Tier 2 -SP_Daily_Dividends, Fact_SnapshotCustomer.IsCreditReportValidCB) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| Fact_CustomerAction | DWH_dbo | Primary -- dividend actions (ActionTypeID=35, IsFeeDividend=2) |
| Dim_Position | DWH_dbo | Position details (InstrumentID, IsSettled) |
| Dim_Instrument | DWH_dbo | Instrument metadata (name, ISIN, exchange, type) |
| Fact_SnapshotCustomer | DWH_dbo | Customer regulation, validity flags |
| Dim_Range | DWH_dbo | Date range resolution |
| Dim_Regulation | DWH_dbo | Regulation name |
| BI_DB_US_Stocks | BI_DB_dbo | US stock classification lookup |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Daily_Dividends |
| **ETL Pattern** | DELETE-INSERT by Date |
| **Grain** | Regulation + Date + InstrumentID + segment + validity flags |
| **Schedule** | Daily (SB_Daily, Priority 99 -- FinanceReportSPS) |
| **Parameter** | @dd (DATE) |
| **Delete Scope** | `DELETE WHERE Date = @dd` |
| **Architecture** | #div (raw dividends) -> #temp (enriched with position/instrument) -> aggregated INSERT |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Filter on Date** | Clustered index on Date. |
| **DividendPaid aggregation** | Already aggregated per instrument per day. For per-customer detail, query Fact_CustomerAction directly. |
| **ASIC CFD treatment** | ASIC-regulated settled positions are classified as CFD_Stocks/CFD_ETF, not Real. |
| **Negative dividends** | Sample shows negative values (e.g., index CFD adjustments). Not always positive payments. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Dividend Reporting |
| **Sub-domain** | Daily Dividend Aggregation |
| **Sensitivity** | Instrument-level (no CID) -- low PII risk |
| **Owner** | Finance team |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 4, Object #6*
*Phases: P1, P2, P8, P9 | Skipped: P3-P7, P9B, P10, P10.5*
