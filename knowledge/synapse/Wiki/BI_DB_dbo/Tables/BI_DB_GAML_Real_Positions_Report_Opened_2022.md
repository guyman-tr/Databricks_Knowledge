# BI_DB_dbo.BI_DB_GAML_Real_Positions_Report_Opened_2022

## 1. Overview

Daily snapshot of **GAML** (`RegulationID = 10`) **real equity positions opened on the run date** (`OpenDateID = @dateID`). Populated in the same execution as `BI_DB_Finance_Non_US_Settlement_Report` from `#relPos2`. **EOD_Value** is end-of-day mark-to-market in USD: `pl.Amount + pl.PositionPnL` as `Total_Open_$` on the run date.

**Row grain**: One row per PositionID in `#relPos2` with `RegulationID = 10` and open date matching the batch date (includes positions still open at EOD).

---

## 2. Business Context

Complements `BI_DB_GAML_Real_Positions_Report_Closed` (same SP): **opened** side carries **unrealized** EOD valuation; **closed** side carries **realized** equity. Naming suffix **2022** reflects table lineage; load logic is the current SP block (not legacy SettlementDB).

**Filters**: Same `#relPos2` rules as sibling tables, then `WHERE RegulationID = 10` with **no** `CloseDateID <> 0` requirement (unlike closed).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 19 |
| **Distribution** | HASH(CID) |
| **Clustered Index** | OpenDateID ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | PositionID | bigint | YES | DWH position identifier. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, #relPos2.PositionID) |
| 2 | CID | int | YES | Customer ID (`Fact_SnapshotCustomer.RealCID`). Distribution key. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, #relPos2.CID) |
| 3 | OpenDateID | int | YES | DateID when position opened; equals `@dateID` for inserted rows. Clustered index column. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, #relPos2.OpenDateID) |
| 4 | InstrumentID | int | YES | Instrument key. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, #relPos2.InstrumentID) |
| 5 | Instrument_Name | varchar(50) | YES | `Dim_Instrument.Name`. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, Dim_Instrument.Name) |
| 6 | ISINCode | varchar(30) | YES | `Dim_Instrument.ISINCode`. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, Dim_Instrument.ISINCode) |
| 7 | Initial_Amount | money | YES | `Dim_Position.InitialAmountCents / 100`. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, Dim_Position.InitialAmountCents) |
| 8 | Regulation_on_Open | tinyint | YES | `Dim_Position.RegulationIDOnOpen`. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, Dim_Position.RegulationIDOnOpen) |
| 9 | Current_IsSettled | int | YES | `BI_DB_PositionPnL.IsSettled` on run date. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, BI_DB_PositionPnL.IsSettled) |
| 10 | UpdateDate | datetime | YES | `GETDATE()` at insert. (Tier 3 -- SP_Finance_Non_US_Settlement_Report, GETDATE()) |
| 11 | OpenOccurred | datetime | YES | `Dim_Position.OpenOccurred`. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, Dim_Position.OpenOccurred) |
| 12 | OpenEOM | date | YES | `EOMONTH(OpenOccurred)`. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, EOMONTH(Dim_Position.OpenOccurred)) |
| 13 | InstrumentType | varchar(50) | YES | `Dim_Instrument.InstrumentType`. Live prod: **Stocks** 7,328,666,990 rows; **ETF** 474,333,736 rows (`COUNT_BIG`). (Tier 2 -- SP_Finance_Non_US_Settlement_Report, Dim_Instrument.InstrumentType) |
| 14 | Is_Copy | int | YES | Mirror copy flag from `MirrorID`. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, Dim_Position.MirrorID) |
| 15 | Exchange | varchar(max) | YES | `Dim_Instrument.Exchange`. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, Dim_Instrument.Exchange) |
| 16 | EOD_Value | money | YES | USD EOD position value: `pl.Amount + pl.PositionPnL` as `Total_Open_$` in `#relPos2`. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, #relPos2.Total_Open_$) |
| 17 | Same_Day_OC | int | YES | Same-day open/close flag. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, CASE dp.OpenDateID = dp.CloseDateID) |
| 18 | Regulation_Name | varchar(50) | YES | `Dim_Regulation.Name`. Live prod: **ASIC & GAML** only (7,803,000,726 rows). (Tier 2 -- SP_Finance_Non_US_Settlement_Report, Dim_Regulation.Name) |
| 19 | IsGermanBaFin | int | YES | German BaFin flag from `V_GermanBaFin`. (Tier 2 -- SP_Finance_Non_US_Settlement_Report, #GermanBafin.CID) |

---

## 5. Relationships

| Object | Relationship |
|--------|----------------|
| SP_Finance_Non_US_Settlement_Report | Writer -- DELETE `OpenDateID = @dateID`, INSERT from `#relPos2` |
| BI_DB_GAML_Real_Positions_Report_Closed | Sibling table (closes on date) in same SP |
| V_BI_DB_GAML_Real_Positions_Report_Opened_2022 | View over this table |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Finance_Non_US_Settlement_Report |
| **Pattern** | DELETE `WHERE OpenDateID = @dateID`; INSERT SELECT |
| **Schedule** | Daily, Priority 99 -- FinanceReportSPS |

---

## 7. Live verification (prod Synapse, read-only)

| Check | Result |
|-------|--------|
| Sample | `SELECT TOP 5 * ... ORDER BY OpenDateID DESC` -- **OpenDateID 20260319**; **EOD_Value** near initial amounts; **Regulation_Name** ASIC & GAML; **InstrumentType** Stocks. |
| Row count | **7,803,000,726** |
| **Regulation_Name** | **ASIC & GAML** only |
| **InstrumentType** | **Stocks** 7,328,666,990; **ETF** 474,333,736 |

---

## 8. Query advisory

| Topic | Guidance |
|-------|----------|
| **OpenDateID** | Clustered index -- always constrain date or range. |
| **Very large row count** | Prefer aggregates or narrow filters; avoid `SELECT *` without TOP. |
| **HASH(CID)** | Use CID for colocated joins to other HASH(CID) BI_DB tables. |

---

## 9. Classification

| Property | Value |
|----------|-------|
| **Domain** | Finance / GAML positions |
| **Sensitivity** | Position-level; CID present |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
