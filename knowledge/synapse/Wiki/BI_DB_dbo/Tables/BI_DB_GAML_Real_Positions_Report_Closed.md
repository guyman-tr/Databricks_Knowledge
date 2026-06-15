# BI_DB_dbo.BI_DB_GAML_Real_Positions_Report_Closed

## 1. Overview

Daily extract of **GAML** (`RegulationID = 10`) **real equity positions that closed on the run date** (`@dateID` matches `Dim_Position.CloseDateID`). Built in the same run as `BI_DB_Finance_Non_US_Settlement_Report` from shared temp pipeline `#relPos2`. Each row is one **position** that is settled, non-US-filtered, and GAML-regulated, with **realized equity** at close and metadata (instrument, exchange, copy flag, BaFin).

**Row grain**: One row per PositionID with `CloseDateID = @dateID` and `RegulationID = 10` in `#relPos2`.

---

## 2. Business Context

Supports GAML reporting and reconciliation alongside the instrument-level finance settlement table. **2021-04-26 change history** notes a fix: the closed table source previously retained open positions and inflated counts; logic now requires `CloseDateID <> 0` on insert.

**Filters** (inherited from `#relPos2`): same as parent SP -- `InstrumentTypeID IN (5,6)`, `IsSettled = 1`, `IsCreditReportValidCB = 1`, `RegulationID NOT IN (6,7,8)` at snapshot join, then **GAML slice** `RegulationID = 10` and **closed-on-date** `CloseDateID <> 0`.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 19 |
| **Distribution** | HASH(CID) |
| **Clustered Index** | CloseDateID ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | PositionID | bigint | YES | DWH position identifier. (Tier 2 -SP_Finance_Non_US_Settlement_Report, #relPos2.PositionID) |
| 2 | CID | int | YES | Customer ID (`Fact_SnapshotCustomer.RealCID`). Distribution key. (Tier 2 -SP_Finance_Non_US_Settlement_Report, #relPos2.CID) |
| 3 | CloseDateID | int | YES | DateID when position closed; equals `@dateID` for inserted rows. Clustered index column. (Tier 2 -SP_Finance_Non_US_Settlement_Report, #relPos2.CloseDateID) |
| 4 | InstrumentID | int | YES | Instrument key. (Tier 2 -SP_Finance_Non_US_Settlement_Report, #relPos2.InstrumentID) |
| 5 | Instrument_Name | varchar(50) | YES | Instrument display name from `Dim_Instrument.Name` in `#relPos2`. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Instrument.Name) |
| 6 | ISINCode | varchar(30) | YES | ISIN from `Dim_Instrument`. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Instrument.ISINCode) |
| 7 | Initial_Amount | money | YES | Initial margin/notional in USD: `Dim_Position.InitialAmountCents / 100`. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Position.InitialAmountCents) |
| 8 | Regulation_on_Open | tinyint | YES | Regulation ID at open (`Dim_Position.RegulationIDOnOpen`). (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Position.RegulationIDOnOpen) |
| 9 | Current_IsSettled | int | YES | 1 = real asset, 0 = CFD asset. From `BI_DB_PositionPnL.IsSettled` on run date. (Tier 5 — Expert Review) |
| 10 | UpdateDate | datetime | YES | Load timestamp `GETDATE()` on insert. (Tier 3 -SP_Finance_Non_US_Settlement_Report, GETDATE()) |
| 11 | CloseOccurred | datetime | YES | Close event timestamp from `Dim_Position`. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Position.CloseOccurred) |
| 12 | CloseEOM | date | YES | Month-end date of close (`EOMONTH(CloseOccurred)`). (Tier 2 -SP_Finance_Non_US_Settlement_Report, EOMONTH(Dim_Position.CloseOccurred)) |
| 13 | InstrumentType | varchar(50) | YES | Instrument type name from `Dim_Instrument.InstrumentType`. Live prod: overwhelmingly **Stocks**; **ETF** second. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Instrument.InstrumentType) |
| 14 | Is_Copy | int | YES | 1 if `MirrorID > 0` on position leg, else 0. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Position.MirrorID) |
| 15 | Exchange | varchar(max) | YES | Exchange from `Dim_Instrument.Exchange`. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Instrument.Exchange) |
| 16 | Realized_Equity | money | YES | `Dim_Position.Amount + Dim_Position.NetProfit` (realized equity at close). (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Position.Amount + NetProfit) |
| 17 | Same_Day_OC | int | YES | 1 if open and close on same DateID, else 0. (Tier 2 -SP_Finance_Non_US_Settlement_Report, CASE OpenDateID = CloseDateID) |
| 18 | Regulation_Name | varchar(50) | YES | `Dim_Regulation.Name` for current snapshot regulation. Live prod: **ASIC & GAML** only for all rows in `COUNT_BIG` distribution. (Tier 2 -SP_Finance_Non_US_Settlement_Report, Dim_Regulation.Name) |
| 19 | IsGermanBaFin | int | YES | 1 if CID in `V_GermanBaFin` for `@dateID`, else 0. (Tier 2 -SP_Finance_Non_US_Settlement_Report, #GermanBafin.CID) |

---

## 5. Relationships

| Object | Relationship |
|--------|----------------|
| SP_Finance_Non_US_Settlement_Report | Writer -- DELETE `CloseDateID = @dateID`, INSERT from `#relPos2` |
| BI_DB_PositionPnL | Source of PnL row for date |
| Dim_Position, Dim_Instrument, Fact_SnapshotCustomer, ... | Same chain as finance settlement SP |
| V_BI_DB_GAML_Real_Positions_Report_Closed | View over this table |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Finance_Non_US_Settlement_Report |
| **Pattern** | DELETE `WHERE CloseDateID = @dateID`; INSERT SELECT |
| **Schedule** | Daily, Priority 99 -- FinanceReportSPS |

---

## 7. Live verification (prod Synapse, read-only)

| Check | Result |
|-------|--------|
| Sample | `SELECT TOP 5 * ... ORDER BY CloseDateID DESC` -- rows with **CloseDateID 20250702** in sample window; **Regulation_Name** ASIC & GAML; **InstrumentType** Stocks; **Is_Copy** 1 on sample rows. |
| Row count | **21,067,621** |
| **Regulation_Name** | Single distinct value: **ASIC & GAML** (21,067,621 rows) |
| **InstrumentType** | **Stocks** 20,634,481; **ETF** 433,140 |

---

## 8. Query advisory

| Topic | Guidance |
|-------|----------|
| **CloseDateID** | Clustered index -- filter run dates or ranges for performance. |
| **HASH(CID)** | Colocation by CID for parallel scans. |
| **Volume** | Table holds multi-year closes; use DateID predicates. |

---

## 9. Classification

| Property | Value |
|----------|-------|
| **Domain** | Finance / GAML positions |
| **Sensitivity** | Position-level; CID present |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
