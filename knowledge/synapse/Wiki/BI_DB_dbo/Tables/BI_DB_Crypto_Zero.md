# BI_DB_dbo.BI_DB_Crypto_Zero

## 1. Overview

Monthly **crypto P&L reconciliation** ("zero calculation") per customer. Compares unrealized P&L at month start vs month end, adds realized P&L from closed positions, and computes total commission. The "zero" concept: if all P&L components are correctly tracked, the total should reconcile (net to an expected value). Used by finance to detect crypto P&L discrepancies.

**Row grain**: One CID + Regulation + Label + Country + SettlementType per Month

---

## 2. Business Context

The third table in the **Crypto RECON** trio (`SP_M_Crypto_RECON`). While the sibling tables track units, this one tracks **money** (P&L and commissions).

**Key business rules**:
- **Unrealized_Start** (`#PnL0`): Unrealized P&L at the day before month start. Uses `BI_DB_PositionPnL.PositionPnL + Dim_Position.FullCommissionByUnits` for positions open before month start.
- **Unrealized_End** (`#PnL1`): Unrealized P&L at month end. Same formula for positions still open at month end.
- **UnRealizedDiff**: `Unrealized_End - Unrealized_Start`.
- **RealizedZero** (`#realized`): `NetProfit + FullCommissionOnClose` for positions closed during the month.
- **TotalZero**: `UnRealizedDiff + RealizedZero` — should reconcile with actual P&L movements.
- **TotalCommission**: Commission delta: `EndCommission - StartCommission + RealizedCommission`.
- **FULL OUTER JOIN**: All three components are joined on CID + Regulation + Label + SettlementType, allowing partial data.
- **BI_DB_PositionPnL dependency**: LEFT JOIN — positions without PnL records get ISNULL(,0).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 14 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Month ASC, CID ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Month | varchar(7) | YES | Calendar month `YYYY-MM`. Part of clustered index. (Tier 2 — SP_M_Crypto_RECON, @date) |
| 2 | CID | int | YES | Customer ID. COALESCE across #PnL0, #PnL1, #realized. Part of clustered index. (Tier 2 — SP_M_Crypto_RECON, Dim_Position.CID) |
| 3 | Regulation | varchar(50) | YES | Regulation name. COALESCE across three temp tables. (Tier 2 — SP_M_Crypto_RECON, Dim_Regulation.Name) |
| 4 | Unrealized_Start | numeric(38,6) | YES | Unrealized P&L (PnL + commission) at day before month start. From #PnL0 using BI_DB_PositionPnL at @DayBeforeStartINT. ISNULL default 0. (Tier 2 — SP_M_Crypto_RECON, BI_DB_PositionPnL.PositionPnL + Dim_Position.FullCommissionByUnits) |
| 5 | Unrealized_End | numeric(38,6) | YES | Unrealized P&L at month end. From #PnL1 using BI_DB_PositionPnL at @endINT. ISNULL default 0. (Tier 2 — SP_M_Crypto_RECON, BI_DB_PositionPnL.PositionPnL + Dim_Position.FullCommissionByUnits) |
| 6 | UnRealizedDiff | numeric(38,6) | YES | Change in unrealized P&L during month. `Unrealized_End - Unrealized_Start`. (Tier 2 — SP_M_Crypto_RECON, computed) |
| 7 | RealizedZero | money | YES | Realized P&L from positions closed during the month. `SUM(NetProfit + FullCommissionOnClose)`. (Tier 2 — SP_M_Crypto_RECON, Dim_Position.NetProfit + FullCommissionOnClose) |
| 8 | TotalZero | numeric(38,6) | YES | Total reconciliation value: `UnRealizedDiff + RealizedZero`. Should reconcile with actual P&L movements. (Tier 2 — SP_M_Crypto_RECON, computed) |
| 9 | TotalCommission | money | YES | Net commission for the month: `EndCommission - StartCommission + RealizedCommission`. (Tier 2 — SP_M_Crypto_RECON, Dim_Position.FullCommissionByUnits + FullCommissionOnClose) |
| 10 | Label | varchar(15) | YES | Brand label from Dim_Label.Name. Values: "eToro", etc. (Tier 2 — SP_M_Crypto_RECON, Dim_Label.Name) |
| 11 | UpdateDate | datetime | YES | SP execution timestamp. GETDATE(). (Tier 3 — SP_M_Crypto_RECON, GETDATE()) |
| 12 | Country | varchar(max) | YES | Country name from Dim_Country.Name. Added Sep 2021. (Tier 2 — SP_M_Crypto_RECON, Dim_Country.Name) |
| 13 | SettlementType | varchar(10) | YES | Settlement classification: "Real", "CFD", "TRS", "CMT". Added Feb 2022. NULL for older data. (Tier 2 — SP_M_Crypto_RECON, Dim_Position.IsSettled + SettlementTypeID) |
| 14 | IsValidCustomer | int | YES | Customer validity flag. Not filtered (since Mar 2022). NULL for older data. (Tier 2 — SP_M_Crypto_RECON, Fact_SnapshotCustomer.IsValidCustomer) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| Dim_Position | DWH_dbo | Primary — position P&L, commission, open/close dates |
| BI_DB_PositionPnL | BI_DB_dbo | Position-level PnL snapshot (LEFT JOIN for unrealized) |
| Dim_Instrument | DWH_dbo | Crypto filter (InstrumentTypeID=10) |
| Fact_SnapshotCustomer | DWH_dbo | Customer regulation, validity flag |
| Dim_Range | DWH_dbo | Date range resolution |
| Dim_Regulation | DWH_dbo | Regulation name |
| Dim_Label | DWH_dbo | Label name |
| Dim_Country | DWH_dbo | Country name |

### Sibling Tables (same SP)

| Table | Relationship |
|-------|-------------|
| BI_DB_Crypto_Net_Units_During_Month | Units during month |
| BI_DB_Crypto_Net_Units_End_Of_Month | Units at month end |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_M_Crypto_RECON |
| **ETL Pattern** | DELETE-INSERT by Month |
| **Grain** | CID + Regulation + Label + Country + SettlementType per Month |
| **Schedule** | Monthly (SB_Monthly, Priority 99 — FinanceReportSPS) |
| **Parameter** | @date (DATE — last day of month) |
| **Delete Scope** | `DELETE WHERE Month = CONVERT(VARCHAR(7), @start, 126)` |
| **Architecture** | 3 temp tables (#PnL0, #PnL1, #realized) → FULL OUTER JOIN into #final → aggregated INSERT |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Filter on Month + CID** | Composite clustered index. |
| **TotalZero interpretation** | Non-zero TotalZero indicates a reconciliation gap — investigate individual components. |
| **BI_DB_PositionPnL dependency** | LEFT JOIN — if PositionPnL data is missing, unrealized components default to 0 + commission only. |
| **Pre-2022 NULLs** | Country (pre-Sep 2021), SettlementType (pre-Feb 2022), IsValidCustomer (pre-Mar 2022) may be NULL. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Crypto Reconciliation |
| **Sub-domain** | Crypto Zero (P&L Reconciliation) |
| **Sensitivity** | Contains CID — PII-adjacent |
| **Owner** | Finance / Crypto RECON team |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline — Batch 4, Object #3*
*Phases: P1 ✓ P2 ✓ P8 ✓ P9 ✓ | Skipped: P3-P7, P9B, P10, P10.5 (shared SP, complex but well-traced)*
