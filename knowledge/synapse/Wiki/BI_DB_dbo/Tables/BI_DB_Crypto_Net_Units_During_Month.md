# BI_DB_dbo.BI_DB_Crypto_Net_Units_During_Month

## 1. Overview

Monthly snapshot of **net crypto units held or transacted during a calendar month** per customer, regulation, and instrument. Captures the net effect of all crypto position openings and closings that occurred or were active within the month. Used by the finance team for monthly crypto reconciliation (the "Crypto RECON" process).

**Row grain**: One CID + Regulation + Instrument + SettlementType per Month

---

## 2. Business Context

This table is part of the **Crypto RECON** trio (populated by `SP_M_Crypto_RECON` alongside `BI_DB_Crypto_Net_Units_End_Of_Month` and `BI_DB_Crypto_Zero`). It answers: "What is the net crypto unit exposure that was active during the month?" -- factoring in positions opened, closed, and held.

**Key business rules**:
- **Units formula**: `SUM(AmountInUnitsDecimal * (2*IsBuy - 1) * (2*Is_open - 1))` -- buys are positive, sells negative; positions still open at month end contribute positively, closed positions contribute negatively. This captures the net flow.
- **Crypto only**: `InstrumentTypeID = 10` filters to crypto instruments.
- **SettlementType**: Real / CFD / TRS / CMT based on `IsSettled` and `SettlementTypeID`.
- **IsValidCustomer**: Included as a column (not filtered) since Mar 2022 change.

**Sibling tables**: `BI_DB_Crypto_Net_Units_End_Of_Month` (snapshot at month end), `BI_DB_Crypto_Zero` (P&L reconciliation).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 8 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Month ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Month | varchar(7) | YES | Calendar month in `YYYY-MM` format (e.g., "2025-04"). Clustered index. Derived from SP @date parameter via `CONVERT(VARCHAR(7), @start, 126)`. (Tier 2 -- SP_M_Crypto_RECON, @date) |
| 2 | CID | int | YES | Customer ID from #pos temp table (sourced from Dim_Position.CID). (Tier 2 -- SP_M_Crypto_RECON, Dim_Position.CID) |
| 3 | Regulation | varchar(50) | YES | Regulation name from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. Values: "CySEC", "FCA", "FinCEN", "ASIC", etc. (Tier 2 -- SP_M_Crypto_RECON, Dim_Regulation.Name) |
| 4 | Instrument | varchar(50) | NO | Crypto instrument name from Dim_Instrument.Name via #pos temp table. Values: "BTC/USD", "ETH/USD", "ADA/USD", etc. NOT NULL constraint. (Tier 2 -- SP_M_Crypto_RECON, Dim_Instrument.Name) |
| 5 | Units | decimal(38,6) | YES | Net crypto units during the month. Formula: `SUM(AmountInUnitsDecimal * (2*IsBuy-1) * (2*Is_open-1))`. Positive = net long activity, negative = net short/closing activity. (Tier 2 -- SP_M_Crypto_RECON, computed) |
| 6 | UpdateDate | datetime | YES | SP execution timestamp. GETDATE(). (Tier 3 -- SP_M_Crypto_RECON, GETDATE()) |
| 7 | SettlementType | varchar(10) | YES | Settlement classification. Values: "Real" (IsSettled=1), "CFD" (SettlementTypeID=0), "TRS" (SettlementTypeID=2), "CMT" (SettlementTypeID=3). NULL for rows before Feb 2022. (Tier 2 -- SP_M_Crypto_RECON, Dim_Position.IsSettled + SettlementTypeID) |
| 8 | IsValidCustomer | int | YES | Customer validity flag from Fact_SnapshotCustomer.IsValidCustomer. 1 = valid. Included but not filtered (since Mar 2022). NULL for pre-2022 data. (Tier 2 -- SP_M_Crypto_RECON, Fact_SnapshotCustomer.IsValidCustomer) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| Dim_Position | DWH_dbo | Primary -- position details, units, buy/sell, settlement |
| Dim_Instrument | DWH_dbo | Instrument name filter (InstrumentTypeID=10 for crypto) |
| Fact_SnapshotCustomer | DWH_dbo | Customer regulation, validity flag |
| Dim_Range | DWH_dbo | Date range resolution for snapshot |
| Dim_Regulation | DWH_dbo | Regulation name |

### Sibling Tables (same SP)

| Table | Relationship |
|-------|-------------|
| BI_DB_Crypto_Net_Units_End_Of_Month | End-of-month snapshot (same SP, different time window) |
| BI_DB_Crypto_Zero | P&L reconciliation (same SP, uses BI_DB_PositionPnL) |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_M_Crypto_RECON |
| **ETL Pattern** | DELETE-INSERT by Month |
| **Grain** | One row per CID + Regulation + Instrument + SettlementType per Month |
| **Schedule** | Monthly (SB_Monthly, Priority 99 -- FinanceReportSPS) |
| **Parameter** | @date (DATE -- last day of month) |
| **Delete Scope** | `DELETE WHERE Month = CONVERT(VARCHAR(7), @start, 126)` |
| **History** | Accumulating monthly snapshots |
| **Architecture** | Uses #pos temp table then JOIN with customer/regulation dims |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Always filter on Month** | Clustered index on Month (varchar). Use `WHERE Month = '2025-04'` format. |
| **Units interpretation** | Positive = net long during month, negative = net short/closing. Not the same as end-of-month holdings. |
| **Pre-2022 NULLs** | SettlementType and IsValidCustomer are NULL for data before Feb/Mar 2022. |
| **Crypto only** | Only InstrumentTypeID=10. No stocks/ETFs/indices. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Crypto Reconciliation |
| **Sub-domain** | Crypto Net Units (During Month) |
| **Sensitivity** | Contains CID -- PII-adjacent |
| **Owner** | Finance / Crypto RECON team |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 4, Object #1*
*Phases: P1, P2, P8, P9 | Skipped: P3-P7, P9B, P10, P10.5 (simple structure, single shared SP)*
